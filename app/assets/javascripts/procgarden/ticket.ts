/// <reference path="ui.ts"/>
/// <reference path="cmd_args.ts"/>
/// <reference path="result_holder.ts"/>
/// <reference path="model.ts"/>
/// <reference path="proc.ts"/>
/// <reference path="fallback.ts"/>

module ProcGarden {
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
        public status_ui: StatusLabelUI = new StatusLabelUI();
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


    //
    export class Input extends Section {
        constructor(proc: Proc) {
            super('run', proc);

            this.tab_ui.activate();
        }

        public tab_ui: ActiveTabUI = new ActiveTabUI();
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

        public change_proc(new_proc: Proc, update_id: boolean = true) {
            this.current_proc = new_proc;
            if ( update_id ) {
                this.data.selected_proc_id = new_proc.id;
            }

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
}