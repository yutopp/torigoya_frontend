/// <reference path="typings/jquery.cookie/jquery.cookie.d.ts"/>
/// <reference path="base64_utf8.ts"/>

module ProcGarden {
    function b64_to_utf8(str: string) {
        try {
            return UTF8ArrToStr(base64DecToArr(str));
        } catch(e) {
            return window.atob(str);
        }
    }

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

    export class TicketFallBack {
        title: string;
        message: string;
    }

    export module Procs {
        export function initial_set(table: any): {
            procs: Array<Proc>;
            group: {[key: string]: Array<Proc>;};
        } {
            var procs: Array<Proc> = [];
            var group: {[key: string]: Array<Proc>;} = {};

            var i = 0;
            for( var proc_id in table ) {
                var proc_config_unit = table[proc_id];

                var description = new ProcDescription(proc_config_unit.Description);
                var proc_profile_table = proc_config_unit.Versioned;

                //
                var versions: Array<string> = [];
                for( var proc_version in proc_profile_table ) {
                    versions.push(proc_version);
                }
                versions = versions.sort((a: string, b: string) => b.localeCompare(a));

                // add procs ordered by version
                versions.forEach((proc_version) => {
                    var proc_profile = proc_profile_table[proc_version];
                    var proc = <Proc>{
                        id: i,
                        value: {proc_id: parseInt(proc_id, 10), proc_version: proc_version},
                        title: description.name + " - " + proc_version,
                        group: description.name,
                        profile: new ProcGarden.ProcProfile(description, proc_profile)
                    }

                    procs.push(proc);

                    group[<string>description.name] = group[<string>description.name] || [];
                    group[<string>description.name].push(proc);

                    i = i + 1;
                });
            }

            return {
                procs: procs,
                group: group
            };
        }

        export function select_default(procs: Array<Proc>): Proc {
            return null;
        }

        export function fallback(
            procs: Array<Proc>,
            proc_id: number,
            proc_version: string,
            ticket: Ticket,
            ticket_model: Model.Ticket
        ) {
            // 1. find exact match
            var match = procs.filter((p) => {
                return p.value.proc_id == proc_id && p.value.proc_version == proc_version;
            });
            if ( match.length != 0 ) {
                return match[0];
            }

            /////////
            var original_title = ( ticket_model.proc_label != null )
                ? ticket_model.proc_label
                : "(???)";

            ticket.fallback = new TicketFallBack;
            ticket.fallback.title = original_title;

            // 2. find HEAD match
            if ( /^HEAD-/.test(proc_version) ) {
                var match = procs.filter((p) => {
                    return p.value.proc_id == proc_id && /^HEAD-/.test(p.value.proc_version);
                });
                if ( match.length != 0 ) {
                    ticket.fallback.message = "Original HEAD is no longer HEAD.";
                    return match[0];
                }
            }

            // 3. language
            var match = procs.filter((p) => {
                return p.value.proc_id == proc_id;
            });
            if ( match.length != 0 ) {
                ticket.fallback.message = "Original version is no longer supported.";
                return match.sort((a, b) => {
                    return b.value.proc_version.localeCompare(a.value.proc_version);
                })[0];  // select newest version;
            }

            // 4. failed
            ticket.fallback.message = "Original language is no longer hosted.";
            return procs[0];
        }
    }

    //
    export class ProcProfile {
        constructor(description: ProcDescription, hash: any) {
            this.description = description;
            this.proc_version = hash.Version;
            //
            this.is_build_required = hash.IsBuildRequired;
            this.is_link_independent = hash.IsLinkIndependent;

            this.source = ( hash.Source != null ) ? new PhaseDetail(hash.Source) : null;
            this.compile = ( hash.Compile != null ) ? new PhaseDetail(hash.Compile) : null;
            this.link = ( hash.Link != null ) ? new PhaseDetail(hash.Link) : null;
            this.run = ( hash.Run != null ) ? new PhaseDetail(hash.Run) : null;
        }

        get proc_id() {
            return this.description.id;
        }

        get name() {
            return this.description.name;
        }

        get is_runnable() {
            return this.description.runnable;
        }

        public description: ProcDescription;
        public proc_version: string;
        public is_build_required: boolean;
        public is_link_independent: boolean;

        public source: PhaseDetail;
        public compile: PhaseDetail;
        public link: PhaseDetail;
        public run: PhaseDetail;
    }

    //
    export class ProcDescription {
        constructor(hash: any) {
            this.id = hash.Id;
            this.name = hash.Name;
            this.runnable = hash.Runnable;
            this.path = hash.Path;
        }

        public id: number;
        public name: string;
        public runnable: boolean;
        public path: string;
    }

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

            this.allowed_command_line = {};
            for( var key in hash.AllowedCommandLine ) {
                var value = hash.AllowedCommandLine[key];
                this.allowed_command_line[key] = new SelectableCommand(value);
            }

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

1    //
    export interface Proc {
        id: number;
        value: {
            proc_id: number;
            proc_version: string;
        };

        title: string;
        group: string;
        profile: ProcProfile;
    }

    //
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

    export class OpenableUI {
        constructor() {
            this.is_option_opened = true; // TODO: make to 'false'
        }

        public toggle_option_opened() {
            this.is_option_opened = !this.is_option_opened;
        }

        public is_option_opened: boolean;
    }

    //
    export class SectionUI extends OpenableUI {
        constructor() {
            super();
        }

        tip_stdout: boolean;
        tip_stderr: boolean;

        wrap_strout: boolean = false;
        wrap_strerr: boolean = false;
    }

    //
    export class Section {
        constructor(mode: string, proc: Proc) {
            this.mode = mode;
            this.change_proc(proc);
        }

        public change_proc(new_proc: Proc) {
            this.current_proc = new_proc;
            this.current_phase_detail = (<any>new_proc.profile)[this.mode];
        }

        public refresh_command_line() {
            var c = this.current_proc.profile;
            this.cmd_args.structured.refresh(
                c.proc_id,
                c.proc_version,
                this.mode,
                this.current_phase_detail.allowed_command_line
            );
        }

        public set_default_command_line() {
            this.cmd_args.structured.set_default(
                this.current_phase_detail.allowed_command_line
            );
        }

        public clear_command_line() {
            this.cmd_args.structured.clear_options();
        }

        public make_command_line_string(is_readonly: boolean): string {
            if ( !is_readonly ) {
                // generate from active data
                return [
                    this.current_phase_detail.command,
                    this.cmd_args.stringified_structured(),
                    this.current_phase_detail.fixed_command_line,
                    this.cmd_args.escaped_freed()
                ].join(' ');

            } else {
                return ( this.result.command != null ) ? this.result.command : '(none...)';
            }
        }

        public reset_result() {
            this.result.reset();
            this.status_ui.update(null);
        }

        public set_result(status: Model.Status) {
            this.result.set(status);
            this.status_ui.update(status);
        }

        public load_init_data_from_model(status: Model.Status) {
            this.cmd_args.structured.load_from_array(status.structured_command_line);
        }

        public ui: SectionUI = new SectionUI();
        public status_ui: StatusLabel = new StatusLabel();
        public mode: string;

        public current_proc: Proc;
        public current_phase_detail: PhaseDetail;

        public cmd_args: CmdArgs = new CmdArgs();
        public stdin: string = "";

        public result: ResultHolder = new ResultHolder();
    }

    //
    export class Compile extends Section {
        constructor(proc: Proc) {
            super('compile', proc);
        }
    }

    //
    export class Link extends Section {
        constructor(proc: Proc) {
            super('link', proc);
        }
    }

    export class ActiveTabUI {
        constructor() {
            this.activate();
        }

        public activate() {
            this.is_active_tab = true;
        }
        public inactivate() {
            this.is_active_tab = false;
        }

        public is_active_tab: boolean;
    }

    //
    export class Input extends Section {
        constructor(proc: Proc) {
            super('run', proc);

            this.tab_ui.activate();
        }

        public tab_ui: ActiveTabUI = new ActiveTabUI();
    }

    export class PhaseLabelUI {
        update(phase: PhaseConstant) {
            if ( phase == null ) {
                this.label = '';
                this.label_style = '';
                return;
            }

            switch( phase ) {
            case PhaseConstant.Waiting:
                this.label = "Waiting..."
                this.label_style = "label-info"
                break;

            case PhaseConstant.NotExecuted:
                this.label = "NotExecuted"
                this.label_style = "label-default"
                break;

            case PhaseConstant.Compiling:
                this.label = "Compiling"
                this.label_style = "label-warning"
                break;

            case PhaseConstant.Compiled:
                this.label = "Compiled"
                this.label_style = "label-success"
                break;

            case PhaseConstant.Linking:
                this.label = "Linking"
                this.label_style = "label-warning"
                break;

            case PhaseConstant.Linked:
                this.label = "Linked"
                this.label_style = "label-success"
                break;

            case PhaseConstant.Running:
                this.label = "Running"
                this.label_style = "label-primary"
                break;

            case PhaseConstant.Finished:
                this.label = "Finished"
                this.label_style = "label-success"
                break;

            case PhaseConstant.Error:
                this.label = "System Error(Please report this page!)"
                this.label_style = "label-danger"
                break;
            }
        }

        public label: string;
        public label_style: string;
    }


    //
    export class Ticket {
        constructor(proc: Proc) {
            this.current_proc = proc;

            this.compile = new Compile(proc);
            this.link = new Link(proc);
            this.inputs = [];

            this.data = {
                selected_proc_id: proc.id
            };

            this.tab_ui.activate();
            this.refresh_command_lines();
        }

        public append_input() {
            this.inputs.forEach((input: Input) => {
                input.tab_ui.inactivate();
            });
            var i = new Input(this.current_proc);
            this.inputs.push(i);
        }

        public update(m: Model.Ticket) {
            this.set_phase(m.phase);

            if ( m.compile_state != null ) {
                this.compile.set_result(m.compile_state);
            }

            if ( m.link_state != null ) {
                this.link.set_result(m.link_state);
            }

            if ( m.phase >= PhaseConstant.Running ) {
                if ( m.run_states != null ) {
                    m.run_states.forEach((status: Model.Status) => {
                        this.inputs[status.index].set_result(status);
                    });
                }
            }
        }

        public load_init_data_from_model(m: Model.Ticket) {
            if ( m.compile_state != null ) {
                this.compile.load_init_data_from_model(m.compile_state);
            }

            if ( m.link_state != null ) {
                this.link.load_init_data_from_model(m.link_state);
            }

            if ( m.phase >= PhaseConstant.Running ) {
                if ( m.run_states != null ) {
                    m.run_states.forEach((status: Model.Status) => {
                        this.inputs[status.index].load_init_data_from_model(status);
                    });
                }
            }
        }

        public change_proc(new_proc: Proc) {
            this.current_proc = new_proc;

            this.compile.change_proc(this.current_proc);
            this.link.change_proc(this.current_proc);
            this.inputs.forEach((input: Input) => {
                input.change_proc(this.current_proc);
            });
        }

        public refresh_command_lines() {
            this.compile.refresh_command_line();
            this.link.refresh_command_line();
            this.inputs.forEach((input: Input) => {
                input.refresh_command_line();
            });
        }

        public set_default_command_lines() {
            this.compile.set_default_command_line();
            this.link.set_default_command_line();
            this.inputs.forEach((input: Input) => {
                input.set_default_command_line();
            });
        }

        public clear_command_lines() {
            this.compile.clear_command_line();
            this.link.clear_command_line();
            this.inputs.forEach((input: Input) => {
                input.clear_command_line();
            });
        }

        public set_phase(p: PhaseConstant) {
            this.phase = p;
            this.phase_ui.update(p);
        }

        public reset() {
            this.set_phase(null);

            this.compile.reset_result();
            this.link.reset_result();
            this.inputs.forEach((input: Input) => {
                input.reset_result();
            });
        }

        private apply_to_all<T>(f: (s: Section) => T) {
            f.call(this.compile);
            f(this.link);
            this.inputs.forEach((input: Input) => {
                f(input);
            });
        }

        public tab_ui: ActiveTabUI = new ActiveTabUI();
        public phase_ui: PhaseLabelUI = new PhaseLabelUI();

        public current_proc: Proc;

        public compile: Compile;
        public link: Link;
        public inputs: Array<Input>;

        public do_execution: boolean = true;
        public is_processing: boolean = false
        public phase: PhaseConstant = null;

        public data: {
            selected_proc_id: number;
        };

        public fallback: TicketFallBack;

        public recieved_until() {
            return {
                compile: {
                    out: this.compile.result.stdout_recieved_line,
                    err: this.compile.result.stderr_recieved_line
                },
                link: {
                    out: this.link.result.stdout_recieved_line,
                    err: this.link.result.stderr_recieved_line
                },
                run: this.inputs.map((input: Input) => {
                    return {
                        out: input.result.stdout_recieved_line,
                        err: input.result.stderr_recieved_line
                    }
                })
            };
        }
    }

    //
    export class CmdArgsUI extends OpenableUI {
        constructor() {
            super();
        }
    }

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

    //
    export enum PhaseConstant {
        Waiting = 0,
        NotExecuted = 10,
        Compiling = 200,
        Compiled = 250,
        Linking = 280,
        Linked = 281,
        Running = 300,
        Finished = 400,
        Error = 401
    }

    //
    export enum StatusConstant {
        MemoryLimit = 1,
        CPULimit = 2,
        OutputLimit = 22,
        Error = 3,
        InvalidCommand = 31,
        Passed = 4,
        UnexpectedError = 5,
    }

    //
    export class StatusLabel {
        constructor() {
            this.update(null);
        }

        public update(result: Model.Status) {
            if ( result == null ) {
                this.label = "NotRunning";
                this.label_style = "label-default";
                return;
            }

            switch( result.status ) {
            case StatusConstant.MemoryLimit:
                this.label = "MemoryLimitExceeded";
                this.label_style = "label-info";
                break;

            case StatusConstant.CPULimit:
                this.label = "TimeLimitExceeded";
                this.label_style = "label-warning";
                break;

            case StatusConstant.OutputLimit:
                this.label = "OutputLimit";
                this.label_style = "label-danger";
                break;

            case StatusConstant.Error:
                this.label = "Error";
                this.label_style = "label-danger";
                break;

            case StatusConstant.InvalidCommand:
                this.label = "InvalidCommand";
                this.label_style = "label-danger";
                break;

            case StatusConstant.Passed:
                if ( result.signal != null || result.return_code == null || result.return_code != 0 ) {
                    this.label = "RuntimeError";
                    this.label_style = "label-danger";
                } else {
                    this.label = "Success";
                    this.label_style = "label-success";
                }
                break;

            case StatusConstant.UnexpectedError:
                this.label = "UnexpectedError(Please report this page...)";
                this.label_style = "label-danger";
                break;
            }
        }

        public label: string;
        public label_style: string;
    }

}