/// <reference path="constants.ts"/>
/// <reference path="model.ts"/>

module ProcGarden {
    //
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
    export class CmdArgsUI extends OpenableUI {
        constructor() {
            super();
        }
    }


    //
    export class StatusLabelUI {
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