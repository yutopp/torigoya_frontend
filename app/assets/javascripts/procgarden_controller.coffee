# AngularJS
ProcGardenApp = angular.module('ProcGardenApp', ['ui.select2', 'ui.bootstrap', 'luegg.directives'])




# ==================================================
# ==================================================
# ==================================================
# ==================================================
# EditorController
ProcGardenApp.controller(
    'SourceCodeEditor',
    ['$scope', ($scope) =>
        #
        $scope.font_size = {
            current: $.cookie("sc-editor-font-size") ? "13px",
            list: ("#{num}px" for num in [8..20])
        }
        $scope.$watchCollection(
            'font_size.current',
            ()=>
                $.cookie("sc-editor-font-size", $scope.font_size.current)
                (new CodemirrorEditor).set_font_size($scope.font_size.current)
        )

        #
        $scope.tab_or_space = {
            current: $.cookie("sc-editor-tab-or-space") ? "space",
            list: [
                "tab",
                "space"
            ]
        }
        $scope.$watchCollection(
            'tab_or_space.current',
            ()=>
                $.cookie("sc-editor-tab-or-space", $scope.tab_or_space.current)
                (new CodemirrorEditor).set_tab_or_space($scope.tab_or_space.current)
        )

        #
        $scope.indent_size = {
            current: $.cookie("sc-editor-indent-size") ? "4",
            list: [
                "2",
                "4",
                "8"
            ]
        }
        $scope.$watchCollection(
            'indent_size.current',
            ()=>
                $.cookie("sc-editor-indent-size", $scope.indent_size.current)
                (new CodemirrorEditor).set_indent_size($scope.indent_size.current)
        )

        #
        $scope.keybind = {
            current: $.cookie("sc-editor-keybind") ? "default",
            list: [
                "default",
                "emacs",
                "vim"
            ]
        }
        $scope.$watchCollection(
            'keybind.current',
            ()=>
                $.cookie("sc-editor-keybind", $scope.keybind.current)
                (new CodemirrorEditor).set_keybind($scope.keybind.current)
        )

        #
        $scope.theme = {
            current: $.cookie("sc-editor-theme") ? "eclipse",
            list: [
                "default",
                "ambiance",
                "blackboard",
                "cobalt",
                "eclipse",
                "elegant",
                "erlang-dark",
                "lesser-dark",
                "monokai",
                "neat",
                "night",
                "rubyblue",
                "twilight",
                "vibrant-ink",
                "xq-dark",
            ]
        }
        $scope.$watchCollection(
            'theme.current',
            ()=>
                $.cookie("sc-editor-theme", $scope.theme.current)
                (new CodemirrorEditor).set_theme($scope.theme.current)
        )


        #
        $scope.dissable_rich_editor = if $.cookie("sc-editor-dissable-rich-editor") then $.cookie("sc-editor-dissable-rich-editor") == 'true' else false
        $scope.$watchCollection(
            'dissable_rich_editor',
            ()=>
                $.cookie("sc-editor-dissable-rich-editor", if $scope.dissable_rich_editor then 'true' else 'false')

                editor = new CodemirrorEditor
                editor.set_dissable_rich_editor_flag($scope.dissable_rich_editor)
                editor.reconfig()
        )



        $scope.is_option_collapsed = $.cookie("sc-editor-is-option-collapsed") == 'true'

        $scope.toggle_option_collapse = () =>
            $scope.is_option_collapsed = !$scope.is_option_collapsed
            $.cookie("sc-editor-is-option-collapsed", $scope.is_option_collapsed.toString())

    ]
)


# ==================================================
# ==================================================
# ==================================================
# ==================================================
# TicketsController
ProcGardenApp.controller(
    'EntryController',
    ['$scope', '$rootScope', '$sce', ($scope, $rootScope, $sce) =>
        $scope.do_save_cookie = true

        $scope.mark_as_not_saving_cookie = () =>
            $scope.do_save_cookie = false

        $scope.create_proc_list = () ->
            # gon.proc_table is set by controller
            # data type is hash and defined in torigoya cage

            # initialize
            init = ProcGarden.Procs.initial_set(gon.proc_table);

            $scope.procs = init.procs
            $scope.procs_group = init.group

        # Language Processor List...
        $scope.procs = []
        $scope.procs_group = {}
        $scope.create_proc_list()

        #
        $scope.submit_able = true
        $scope.is_running = false

        #
        $scope.current_entry_id = null
        $scope.current_entry_tweet = null
        $scope.current_entry_target_url = ""

        #
        $scope.visibility = if $.cookie("sc-entry-visibility") then parseInt($.cookie("sc-entry-visibility")) else @VisibilityProtected
        $scope.$watch(
            'visibility',
            (new_value)=>
                unless new_value?
                    return

                if $scope.do_save_cookie
                    $.cookie("sc-entry-visibility", new_value)
        )

        $scope.tickets = []

        ########################################
        # Tab index of Ticket
        $scope.selected_tab_index = 0
        $scope.selected_ticket = null

        $scope.change_ticket_tab = (index) =>
            $scope.selected_tab_index = index
            $scope.selected_ticket = $scope.tickets[index]


        ########################################
        # Tab index of Inputs
        $scope.selected_input_tab_index = 0
        $scope.selected_input = null

        $scope.change_input_tab = (index) =>
            $scope.selected_input_tab_index = index
            $scope.selected_input = $scope.selected_ticket.inputs[index]


        ########################################
        # change editor highlight by selected item
        $scope.$watch(
            'selected_ticket.data.selected_proc_id',
            (new_id, old_id) =>
                # console.log old_value, new_value
                unless new_id?
                    $scope.submit_able = false
                    return
                $scope.submit_able = true

                # new_proc: ProcGarden.Proc
                new_proc = $scope.procs[new_id]

                if $scope.do_save_cookie
                    $.cookie("sc-editor-cached-language-title", new_proc.title)

                selected_ticket = $scope.tickets[$scope.selected_tab_index]
                unless selected_ticket?
                    return
                old_proc = selected_ticket.current_proc

                selected_ticket.change_proc(new_proc, false)

                if new_proc.id != old_proc.id
                    (new CodemirrorEditor).set_highlight(new_proc.title)
                    selected_ticket.refresh_command_lines()
        )


        #
        $scope.$watchCollection(
            'selected_ticket.compile.cmd_args.structured.selected_data',
            (new_value)=>
                unless new_value?
                    return

                ticket = $scope.tickets[$scope.selected_tab_index]
                ticket.compile.cmd_args.structured.save($scope.do_save_cookie)
        )

        #
        $scope.$watchCollection(
            'selected_ticket.link.cmd_args.structured.selected_data',
            (new_value)=>
                unless new_value?
                    return

                ticket = $scope.tickets[$scope.selected_tab_index]
                ticket.link.cmd_args.structured.save($scope.do_save_cookie)
        )

        #
        $scope.$watchCollection(
            '$scope.selected_input.cmd_args.structured.selected_data',
            (new_value)=>
                unless new_value?
                    return

                ticket = $scope.tickets[$scope.selected_tab_index]
                input = ticket.inputs[$scope.selected_input_tab_index]
                input.cmd_args.structured.save($scope.do_save_cookie)
        )

        ########################################
        #
        $scope.append_ticket = () =>
            for ticket in $scope.tickets
                ticket.tab_ui.inactivate()

            # type: ProcGarden.Proc
            default_proc = ProcGarden.Procs.select_default($scope.procs)

            # ticket format
            ticket = new ProcGarden.Ticket(default_proc)
            $scope.tickets.push(ticket)

            # the ticket must has inputs at least one.
            ticket.append_input()

        ########################################
        #
        $scope.force_set_ticket_tab_index = (ticket_index) =>
            for ticket in $scope.tickets
                ticket.tab_ui.inactivate()
            $scope.tickets[ticket_index].tab_ui.activate()
            $scope.change_ticket_tab(ticket_index)


        ########################################
        #
        $scope.append_input = (ticket_index) =>
            $scope.tickets[ticket_index].append_input()


        ########################################
        $scope.reset_entry = () =>
            for ticket, ticket_index in $scope.tickets
                $scope.tickets[ticket_index].reset()




        ########################################
        # phase 1
        $scope.submit_all = () =>
            $scope.is_running = true
            $scope.reset_entry()

            # console.log "submit all!"
            source_code = (new CodemirrorEditor).get_value()
            # console.log source_code

            # !!!! construct POST data
            raw_submit_data = {
                description: "",
                visibility: $scope.visibility,
                source_codes: [
                    source_code
                ],
                tickets: ({
                    proc_id: ticket.current_proc.value.proc_id,
                    proc_version: ticket.current_proc.value.proc_version,
                    do_execution: ticket.do_execution,
                    compile: {
                        structured_command_line: ticket.compile.cmd_args.structured.to_valarray(),
                    },
                    link: {
                        structured_command_line: ticket.link.cmd_args.structured.to_valarray(),
                    },
                    inputs: ({
                        structured_command_line: input.cmd_args.structured.to_valarray(),
                        command_line: input.cmd_args.freed,
                        stdin: input.stdin
                    } for input in ticket.inputs)
                } for ticket in $scope.tickets)
            }

            submit_data = {
                api_version: 1,
                type: "json",
                value: JSON.stringify(raw_submit_data)
            }
            # console.log "submit => ", submit_data

            # submit!
            $.post("/api/system/source", submit_data, "json")
                .done (data) =>
                    $rootScope.$apply () =>
                        if data.is_error
                            alert("Error[1](please report): #{data.message}")
                            $scope.finish_ticket()
                        else
                            $scope.wait_entry_for_update(data.entry_id)
                .fail () =>
                    $rootScope.$apply () =>
                        alert("Failed[1]")
                        $scope.finish_ticket()


        ########################################
        # phase 2
        $scope.wait_entry_for_update = (entry_id, with_init = false) =>
            $scope.is_running = true

            $.get("/api/system/entry/#{entry_id}", "json")
                .done (data) =>
                    $rootScope.$apply () =>
                        if data.is_error
                            alert("Error[2](please report): #{data.message}")
                            $scope.finish_ticket()
                        else
                            ticket_ids = data.ticket_ids

                            $scope.current_entry_id = entry_id

                            # make parmlink button
                            $scope.current_entry_target_url = "http://test.sc.yutopp.net/entries/#{$scope.current_entry_id}"
                            text = "[ProcGarden]⊂二二二（ ◔⊖◔）二⊃"
                            tweet_url = "https://platform.twitter.com/widgets/tweet_button.html?url=#{$scope.current_entry_target_url}&text=#{text}"
                            $scope.current_entry_tweet = $sce.trustAsResourceUrl(tweet_url)

                            # console.log "Entry Loaded: " + JSON.stringify(data)

                            if with_init
                                # make tickets
                                $scope.tickets = []
                                # console.log "ticket_ids", ticket_ids
                                for i in [0...(ticket_ids.length)]
                                    $scope.append_ticket()
                                $scope.force_set_ticket_tab_index(0)

                                # load source code
                                $scope.visibility = data.entry.visibility

                            # console.log data.ticket.num
                            # apply for all tickets
                            ticket_ids.forEach((ticket_id) =>
                                # set processing flag
                                # $scope.tickets[i].is_processing = true
                                # make handler for get ticket data per ticket
                                $scope.wait_ticket_for_update(ticket_id, with_init)
                            )

                .fail () =>
                    $rootScope.$apply () =>
                        alert("Failed[2]")
                        $scope.finish_ticket(ticket_index)


        ########################################
        # phase 3
        $scope.wait_ticket_for_update = (ticket_id, with_init = false, ticket_index = null) =>
            # console.log "wait_ticket_for_update=>", ticket_id

            submit_data = {
                api_version: 1,
                type: "json"
            }
            if ticket_index?
                target_ticket = $scope.tickets[ticket_index]
                raw_submit_data = target_ticket.recieved_until()
                submit_data.value = JSON.stringify(raw_submit_data)

            # console.log "submit => ", submit_data

            $.get("/api/system/ticket/#{ticket_id}", submit_data, "json")
                .done (data) =>
                    # console.log( "Data Loaded: " + JSON.stringify(data) )
                    $rootScope.$apply () =>
                        if data.is_error
                            alert("Error[3](please report): #{data.message}")
                            $scope.finish_ticket()
                        else
                            ticket_model = data.ticket
                            ticket_index = ticket_model.index
                            # console.log "Ticket Loaded: " + JSON.stringify(ticket_model)

                            if with_init
                                $scope.load_ticket_profile(ticket_index, ticket_model)

                            #
                            $scope.tickets[ticket_index].update(ticket_model)

                            # console.log "ticket", ticket_index, ticket_model

                            if ticket_model["is_running"]
                                # set processing flag
                                $scope.tickets[ticket_index].is_processing = true
                                if $scope.selected_tab_index == ticket_index
                                    setTimeout( (() => $scope.wait_ticket_for_update(ticket_id, false, ticket_index) ), 200 ) # recursive call
                                else
                                    setTimeout( (() => $scope.wait_ticket_for_update(ticket_id, false, ticket_index) ), 2000 ) # recursive call
                            else
                                # set processing flag
                                $scope.finish_ticket(ticket_index)
                .fail () =>
                    $rootScope.$apply () =>
                        alert("Failed[3]")
                        $scope.finish_ticket()


        ########################################
        $scope.finish_ticket = (ticket_index) =>
            f = (i) =>
                $scope.tickets[i].is_processing = false
                for input, index in $scope.tickets[i].inputs
                    $scope.tickets[i].inputs[index].is_running = false

            if ticket_index?
                f(ticket_index)
            else
                for ticket, index in $scope.tickets
                    f(index)

            $scope.is_running = false


        ########################################
        #
        $scope.load_ticket_profile = (ticket_index, ticket_model) =>
            proc_id = ticket_model.proc_id
            proc_version = ticket_model.proc_version

            ticket = $scope.tickets[ticket_index]
            found_proc = ProcGarden.Procs.fallback($scope.procs, proc_id, proc_version, ticket, ticket_model)

            #
            ticket.change_proc(found_proc)

            # inputs number error correction
            if ticket_model.run_states?
                ticket.inputs = []
                for i in ticket_model.run_states
                    ticket.append_input()

            #
            ticket.refresh_command_lines()
            ticket.load_init_data_from_model(ticket_model)




    ]
)








# ==================================================
# ==================================================
# ==================================================
# ==================================================
#
ProcGardenApp.controller(
    'RunnerNodeAddresses',
    ['$scope', ($scope) =>
        $scope.nodes = @sc_g_runner_table
    ]
)





# ==================================================
# ==================================================
#

# ==================================================
# ==================================================
# ==================================================
class CodemirrorEditor
    constructor: (option) ->
        @name = "sc-code-editor"

        window.torigoya = {} unless window.hasOwnProperty('torigoya')
        window.torigoya.editor = {} unless window.torigoya.hasOwnProperty('editor')
        window.torigoya.editor[@name] = {} unless window.torigoya.editor.hasOwnProperty(@name)

        @dissable_rich_editor_flag = window.torigoya?.editor[@name]?.dissable_rich_editor ? false

        @option = option if option?

        @_reset_editor()


    get_value: () =>
        return if @dissable_rich_editor_flag then $(@_get_editor_dom()).val() else @editor.doc.getValue()


    set_value: (s) =>
        if s?
            if @dissable_rich_editor_flag then $(@_get_editor_dom()).val(s) else @editor.doc.setValue(s)


    set_font_size: (font_size_px) =>
        window.torigoya.editor[@name].font_size_px = font_size_px
        $(@_get_editor_dom()).css('font-size', font_size_px)
        @dom?.css('font-size', font_size_px)
        @editor?.refresh()

    set_tab_or_space: (indent_type) =>
        window.torigoya.editor[@name].indent_type = indent_type
        @editor?.setOption('indentWithTabs', indent_type == 'tab')
        @editor?.refresh()

    set_indent_size: (indent_size) =>
        window.torigoya.editor[@name].indent_size = indent_size

        indent_size = parseInt(indent_size, 10) unless indent_size instanceof Number
        @editor?.setOption('tabSize', indent_size);
        @editor?.setOption('indentUnit', indent_size);
        @editor?.refresh()

    set_keybind: (keybind) =>
        window.torigoya.editor[@name].keybind = keybind
        @editor?.setOption('keyMap', keybind)
        @editor?.refresh()

    set_theme: (theme) =>
        window.torigoya.editor[@name].theme = theme
        @editor?.setOption("theme", theme)
        @editor?.refresh()


    set_highlight: (language_title) =>
        unless language_title?
            return

        window.torigoya.editor[@name].language_title = language_title
        lang =
            if (/^c\+\+/i.test(language_title))
                { mime: "text/x-c++src", mode: "clike" }
            else if (/^python/i.test(language_title))
                { mime: "text/x-python", mode: "python" }
            else if (/^javascript/i.test(language_title))
                { mime: "text/javascript", mode: "javascript" }
            else if (/^java/i.test(language_title))
                { mime: "text/x-java", mode: "clike" }
            else if (/^ocaml/i.test(language_title))
                { mime: "text/x-ocaml", mode: "mllike" }
            else if (/^d/i.test(language_title))
                { mime: "text/x-d", mode: "d" }
            else if (/^c/i.test(language_title))
                { mime: "text/x-csrc", mode: "clike" }
            else
                console.log "editor_highlight: #{language_title} is not supported"
                null

        unless lang?
            return

        ## http://codemirror.net/mode/
        # console.log "@sc_change_editor_highlight: #{lang.mime}"
        # apl.js
        # asterisk.js
        # clike.js
        # clojure.js
        # cobol.js
        # coffeescript.js
        # commonlisp.js
        # css.js
        # diff.js
        # d.js
        # ecl.js
        # erlang.js
        # gas.js
        # gfm.js
        # go.js
        # groovy.js
        # haml.js
        # haskell.js
        # haxe.js
        # htmlembedded.js
        # htmlmixed.js
        # http.js
        # jade.js
        # javascript.js
        # jinja2.js
        # less.js
        # livescript.js
        # lua.js
        # markdown.js
        # mirc.js
        # nginx.js
        # ntriples.js
        # ocaml.js
        # pascal.js
        # perl.js
        # php.js
        # pig.js
        # properties.js
        # python.js
        # q.js
        # r.js
        # rpm-changes.js
        # rpm-spec.js
        # rst.js
        # ruby.js
        # rust.js
        # sass.js
        # scheme.js
        # scss_test.js
        # shell.js
        # sieve.js
        # smalltalk.js
        # smarty.js
        # smartymixed.js
        # sparql.js
        # sql.js
        # stex.js
        # tcl.js
        # tiddlywiki.js
        # tiki.js
        # turtle.js
        # vb.js
        # vbscript.js
        # velocity.js
        # verilog.js
        # xml.js
        # xquery.js
        # yaml.js
        # z80.js

        # set to CodeMirror Editor
        @editor?.setOption("mode", lang.mime)
        CodeMirror.autoLoadMode(@editor, lang.mode) if @editor?

        @editor?.refresh()


    ########################################
    #
    set_dissable_rich_editor_flag: (do_dissable) =>
        @dissable_rich_editor_flag = do_dissable
        window.torigoya.editor[@name].dissable_rich_editor = do_dissable

        @_reset_editor(true, true)


    ########################################
    #
    reconfig: () =>
        if @dissable_rich_editor_flag
            return

        @set_font_size(window.torigoya.editor[@name].font_size_px)
        @set_tab_or_space( window.torigoya.editor[@name].indent_type)
        @set_indent_size(window.torigoya.editor[@name].indent_size)
        @set_keybind(window.torigoya.editor[@name].keybind)
        @set_theme(window.torigoya.editor[@name].theme)
        @set_highlight(window.torigoya.editor[@name].language_title)


    ########################################
    #
    _reset_editor: (do_force_reset = false, do_reset_without_size = false) =>
        p = $('.CodeMirror')
        # if .Codemirror exists, restore...
        if p.length == 0
            unless @dissable_rich_editor_flag
                # create new CodeMirror object
                CodeMirror.modeURL = "/assets/codemirror/modes/%N.js";
                @editor = CodeMirror.fromTextArea(@_get_editor_dom())
                @dom = $('.CodeMirror')

                # save object
                window.torigoya_editor_object = {} unless window.hasOwnProperty('torigoya_editor_object')
                window.torigoya_editor_object[@name] = @editor

                #
                do_force_reset = true

                # jquery UI
                @dom.resizable({
                    resize: () =>
                        window.torigoya.editor[@name].width = @dom.width()
                        window.torigoya.editor[@name].height = @dom.height()

                        $(@_get_editor_dom()).width(window.torigoya.editor[@name].width).height(window.torigoya.editor[@name].height)
                        @editor.setSize(window.torigoya.editor[@name].width, window.torigoya.editor[@name].height)
                        @editor.refresh()
                });
        else
            # restore from saved object...
            unless @dissable_rich_editor_flag
                @editor = window.torigoya_editor_object[@name]
                @dom = $('.CodeMirror')
            else
                @editor?.toTextArea()

        # load options
        if @option?
            window.torigoya_editor_option = {} unless window.hasOwnProperty('torigoya_editor_option')
            window.torigoya_editor_option[@name] = @option
        else
            @option = window.torigoya_editor_option[@name]

        @_apply_options(do_force_reset, do_reset_without_size)


    _apply_options: (do_force_reset, do_reset_without_size) =>
        unless do_force_reset
            return

        # set options
        if @option?
            editor_config = {
                lineNumbers: true,
                styleActiveLine: true,
                lineWrapping: true,
                matchBrackets: true,
                viewportMargin: Infinity,
                readOnly: if @option?.readonly? then @option.readonly else false
                extraKeys: {
                    Tab: @_code_mirror_extra_tab
                }
            }
            for keymap, f of @option?.extra_key
                editor_config.extraKeys[keymap] = f

            for k, v of editor_config
                @editor?.setOption(k, v)

            #
            if do_reset_without_size
                $(@_get_editor_dom()).width(window.torigoya.editor[@name].width).height(window.torigoya.editor[@name].height)
                @editor?.setSize(window.torigoya.editor[@name].width, window.torigoya.editor[@name].height)
            else
                raw_dom = $(@_get_editor_dom())

                if @option?.height?
                    raw_dom.height(@option.height)
                    @editor?.setSize(null, @option.height)

                if @option?.readonly
                    raw_dom.attr({ readonly: "readonly" })

                window.torigoya.editor[@name].width = if @dom? then @dom.width() else raw_dom.width() unless window.torigoya.editor[@name].width?
                window.torigoya.editor[@name].height = if @dom? then @dom.height() else raw_dom.height() unless window.torigoya.editor[@name].height?

            @editor?.refresh()


    _get_editor_dom: () =>
        return document.getElementById("sc-code-editor")

    _code_mirror_extra_tab: (cm) =>
        if (cm.somethingSelected())
            cm.indentSelection("add")

        else
            cursor = cm.getCursor()
            indent_width = parseInt(cm.getOption("indentUnit"), 10)
            width_array = ((if ch == '\t' then indent_width else 1) for ch in cm.getLine(cursor.line)[0...cursor.ch])
            current_position = if width_array.length == 0 then 0 else (width_array.reduce (x,y) -> x + y)
            result_length = if (current_position % indent_width == 0) then indent_width else (indent_width - current_position % indent_width)

            cm.replaceSelection(
                (if cm.getOption("indentWithTabs") then "\t" else (Array(result_length + 1).join(' '))),
                "end",
                "+input"
                )


# ==================================================
# Editor Settngs
# ==================================================
# Ready
@sc_setup_editor = (option = {}) ->
    window.torigoya = {}
    new CodemirrorEditor(option)


options_to_s = (options) =>
    return "" unless options?

    memo = []
    for option in options
        for key, value of option
            memo.push "#{key}#{if value? then value else ''}" # space required

    return memo.join(' ')

escapeshell = (cmd) =>
    return if cmd?.length > 0 then "\"" + cmd.replace(/(["\s'$`\\])/g,'\\$1') + "\"" else ""
