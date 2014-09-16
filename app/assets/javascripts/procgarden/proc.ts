/// <reference path="profile.ts"/>

module ProcGarden {
    //
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
}