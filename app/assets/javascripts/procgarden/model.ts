module ProcGarden {
    export module Model {
        export interface Ticket {
            index: number;

            is_running: boolean;
            processed: boolean;
            do_execute: boolean;
            proc_id: number;
            proc_version: string;
            proc_label: string;

            phase: number;

            compile_state: Status;
            link_state: Status;
            run_states: Array<Status>;
        }

        export interface Status {
            index: number;

            type: number;

            used_cpu_time_sec: number;
            used_memory_bytes: number;
            signal: number;
            return_code: number;
            command_line: string;   // total
            status: number;
            system_error_message: string;

            structured_command_line: Array<Array<string>>;
            cpu_time_sec_limit: number;
            memory_bytes_limit: number;

            out: string;
            out_until: number;

            err: string;
            err_until: number;
        }
    }
}