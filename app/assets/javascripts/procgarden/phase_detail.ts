module ProcGarden {
    //
    export class SelectableCommand {
        constructor(hash: any) {
            this.defaults = hash.Default;
            this.select = hash.Select;
        }

        public defaults: Array<string>;
        public select: Array<string>;
    }

    //
    export interface AllowedCommands {
        [key: string]: SelectableCommand;
    };

    //
    export class PhaseDetail {
        constructor(hash: any) {
            this.file = hash.File;
            this.extention = hash.Extention;
            this.command = hash.Command;
            this.env = hash.Env;

            //
            this.allowed_command_line = {};
            for( var key in hash.AllowedCommandLine ) {
                var value = hash.AllowedCommandLine[key];
                this.allowed_command_line[key] = new SelectableCommand(value);
            }

            //
            var f: Array<string> = [];
            if ( hash.FixedCommandLine != null ) {
                hash.FixedCommandLine.forEach((cmd: Array<string>) => {
                    if ( cmd.length == 1 ) {
                        f.push(cmd[0])
                    } else if ( cmd.length == 2 ) {
                        f.push(cmd[0]+cmd[1])
                    }
                });
            }
            this.fixed_command_line = f.join(' ');
        }

        public file: string;
        public extention: string;
        public command: string;

        private env: any; // fix it

        public allowed_command_line: AllowedCommands;
        public fixed_command_line: string;
    }
}