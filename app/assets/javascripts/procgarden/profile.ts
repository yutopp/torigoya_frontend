/// <reference path="phase_detail.ts"/>

module ProcGarden {
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
}