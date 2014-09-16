/// <reference path="utils.ts"/>
/// <reference path="model.ts"/>

module ProcGarden {
    export class ResultHolder {
        constructor() {
            this.status = null;
            this.signal = null;
            this.exit = null;

            this.stdout = "";
            this.stderr = "";
            this.cpu = 0;
            this.memory = 0;
            this.command = "";

            this.cpu_limit = 0;
            this.memory_limit = 0;
        }

        public reset() {
            this.status = null;
            this.signal = null;
            this.exit = null;

            this.stdout = (this.stdout != null && this.stdout.length > 0) ? " " : "";
            this.stderr = (this.stderr != null && this.stderr.length > 0) ? " " : "";
            this.cpu = 0;
            this.memory = 0;
            this.command = "";

            this.cpu_limit = 0;
            this.memory_limit = 0;

            this.is_clean = true;

            this.stdout_recieved_line = 0;
            this.stderr_recieved_line = 0;
        }

        public set(result: Model.Status) {
            this.status     = result.status;
            this.cpu        = result.used_cpu_time_sec;
            this.memory     = result.used_memory_bytes;
            this.signal     = result.signal;
            this.exit       = result.return_code;

            this.command    = result.command_line;
            // this.system_error_message

            this.cpu_limit = result.cpu_time_sec_limit;
            this.memory_limit = result.memory_bytes_limit;

            // out and err is encoded by base64, so do decodeing
            if ( this.is_clean ) {
                this.stdout     = (result.out != null) ? b64_to_utf8(result.out) : "";
                this.stderr     = (result.err != null) ? b64_to_utf8(result.err) : "";
                this.is_clean = false;

            } else {
                this.stdout     += (result.out != null) ? b64_to_utf8(result.out) : "";
                this.stderr     += (result.err != null) ? b64_to_utf8(result.err) : "";
            }

            if ( result.out_until != null ) {
                this.stdout_recieved_line = result.out_until;
            }

            if ( result.err_until != null ) {
                this.stderr_recieved_line = result.err_until;
            }
        }

        public get_cpu_string(): string {
            return ""+this.cpu.toFixed(4)+'/'+this.cpu_limit;
        }

        public get_mem_string(): string {
            return mem_dc(this.memory)+'/'+mem_dc(this.memory_limit);
        }

        public status: number;
        public signal: number;
        public exit: number;

        public stdout: string;
        public stderr: string;
        public cpu: number;
        public memory: number;
        public command: string;

        public cpu_limit: number;
        public memory_limit: number;

        private is_clean: boolean = true;

        public stdout_recieved_line: number = 0;
        public stderr_recieved_line: number = 0;
    }
}