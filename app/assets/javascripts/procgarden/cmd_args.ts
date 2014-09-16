/// <reference path="../typings/jquery.cookie/jquery.cookie.d.ts"/>
/// <reference path="ui.ts"/>
/// <reference path="phase_detail.ts"/>

module ProcGarden {
    //
    export class CmdArgs {
        constructor() {
            this.structured = new StructuredCommandLine();
            this.freed = "";
        }

        public has_option(): boolean {
            return this.structured.has_selectable();
        }

        public stringified_structured(): string {
            return this.options_to_s(this.structured);
        }

        public escaped_freed(): string {
            return this.escapeshell(this.freed);
        }

        private options_to_s(options: StructuredCommandLine): string {
            if ( options == null ) {
                return "";
            }

            return options.selected_data.map((d: Select2OptionData) => {
                return d.text;
            }).join(' ');
        }

        private escapeshell(cmd: string): string {
            return ( cmd.length > 0 )
                ? ( "\"" + cmd.replace(/(["\s'$`\\])/g,'\\$1') + "\"" )
                : "";
        }

        public ui: CmdArgsUI = new CmdArgsUI();

        public structured: StructuredCommandLine;
        public freed: string;
    }

    //
    export interface Command {
        [key: string]: string;
    }

    export interface Select2OptionData {
        id: number;
        text: string;
        value: Array<string>;    // ['-std', '=11'] or ['-O0'] etc...
    }

    //
    export interface Select2Options {
        multiple: boolean;
        data: Array<Select2OptionData>;
    }

    //
    export class StructuredCommandLine {
        constructor() {
            this.wrap = "off";

            this.select2_options = {
                multiple: true,
                data: []
            };

            this.clear_options();
        }

        public wrap: string;

        public has_selectable(): boolean {
            return this.select2_options.data.length > 0;
        }

        public refresh(
            proc_id: number,
            proc_version: string,
            mode: string,
            allowed_commands: AllowedCommands
        ) {
            this.cookie_id = "sc-language-" + proc_id.toString() + "-" + proc_version + "-options-with-titles-" + mode;

            this.update(allowed_commands);
            this.load();
        }

        public save(do_save_cookie: boolean) {
            if ( do_save_cookie ) {
                var titles = this.selected_data.map((d: Select2OptionData) => d.text);

                if ( this.cookie_id != null ) {
                    $.cookie(this.cookie_id, JSON.stringify(titles))
                }
            }
        }

        public load() {
            if ( this.cookie_id != null ) {
                var c = $.cookie(this.cookie_id);
                if ( c != null ) {
                    var titles = <Array<string>>JSON.parse(c);
                    this.clear_options();

                    titles.forEach((title: string) => {
                        this.select2_options.data.filter((d: Select2OptionData) => {
                            return d.text == title;
                        }).forEach((d: Select2OptionData) => {
                            this.selected_data.push(d);
                        });
                    });
                }
            }
        }

        public update(allowed_commands: AllowedCommands) {
            this.select2_options.data = [];
            this.clear_options();

            var i: number = 0;
            for( var key in allowed_commands ) {
                var command = allowed_commands[key];
                if ( command != null ) {
                    if ( command.select != null ) {
                        // selectable
                        command.select.forEach((arg: string) => {
                            this.select2_options.data.push({
                                id: i,
                                text: key+arg,
                                value: [key, arg]
                            });
                            ++i;
                        });

                    } else {
                        // key only
                        this.select2_options.data.push({
                            id: i,
                            text: key,
                            value: [key]
                        });
                    }
                }
            }
        }

        public clear_options() {
            this.selected_data = [];
        }

        public set_default(allowed_commands: AllowedCommands) {
            this.clear_options();

            for( var key in allowed_commands ) {
                var command = allowed_commands[key];
                if ( command != null ) {
                    if ( command.defaults != null ) {
                        command.defaults.forEach((arg: string) => {
                            this.select2_options.data.filter((d: Select2OptionData) => {
                                return d.text == key+arg;
                            }).forEach((d: Select2OptionData) => {
                                this.selected_data.push(d);
                            });
                        });
                    }
                }
            }
        }

        public load_from_array(args: Array<Array<string>>) {
            this.clear_options();

            args.forEach((arg_set: Array<string>) => {
                this.select2_options.data.filter((d: Select2OptionData) => {
                    if ( d.value.length != arg_set.length ) {
                        return false;
                    }
                    if ( d.value.length != 1 && d.value.length != 2 ) {
                        return false;
                    }
                    if ( d.value.length == 1 ) {
                        return arg_set[0] == d.value[0];
                    } else if ( d.value.length == 2 ) {
                        return arg_set[0] == d.value[0] && arg_set[1] == d.value[1];
                    }
                }).forEach((d: Select2OptionData) => {
                    this.selected_data.push(d);
                });
            });
        }

        public to_valarray(): Array<Array<string>> {
            return this.selected_data.map((s) => s.value);
        }

        public select2_options: Select2Options;

        private cookie_id: string = null;
        public selected_data: Array<Select2OptionData>;
    }
}