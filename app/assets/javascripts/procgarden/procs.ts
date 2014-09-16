/// <reference path="../typings/jquery.cookie/jquery.cookie.d.ts"/>
/// <reference path="proc.ts"/>
/// <reference path="model.ts"/>
/// <reference path="ticket.ts"/>

module ProcGarden {
    //
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
            try {
                if ( $.cookie("sc-editor-cached-language-title") != null ) {
                    var cached_proc_title = <string>$.cookie("sc-editor-cached-language-title");
                    var found_index: number = null
                    procs.forEach((proc: Proc, index: number) => {
                        if ( found_index == null ) {
                            if ( cached_proc_title == proc.title ) {
                                found_index = index;
                            }
                        }
                    });
                    if ( found_index != null ) {
                        return procs[found_index];
                    } else {
                        throw "proc index not found";
                    }

                } else {
                    // set default...
                    // find c++(gcc)
                    var match = procs.filter((p) => {
                        return p.value.proc_id == 100 && p.value.proc_version == "4.9.1";
                    });
                    if ( match.length != 0 ) {
                        return match[0];
                    }

                    throw "proc index not found";
                }
            } catch(error) {
                return procs[0];    // default value
            }
        }

        export function fallback(
            procs: Array<Proc>,
            proc_id: number,
            proc_version: string,
            ticket: any /*Ticket*/,
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
}