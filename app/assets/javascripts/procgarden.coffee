# AngularJS
ProcGardenApp = angular.module('ProcGardenApp', ['ui.select2', 'ui.bootstrap', 'luegg.directives'])

class PhaseConstatnt
    @Waiting = 0
    @NotExecuted = 10
    @Compiling = 200
    @Compiled = 250
    @Linking = 280
    @Linked = 281
    @Running = 300
    @Finished = 400
    @Error = 401


class StatusConstatnt
    @MemoryLimit = 1
    @CPULimit = 2
    @OutputLimit = 22
    @Error = 3
    @InvalidCommand = 31
    @Passed = 4
    @UnexpectedError = 5





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

class UILabel
    constructor: () ->
        @label_style = "label-default"
        @label = "NotRunning"

    set_ui_label: (result) =>
        unless result?
            @label = "NotRunning"
            @label_style = "label-default"
            return

        switch result.status
            when StatusConstatnt.MemoryLimit
                @label = "MemoryLimitExceeded"
                @label_style = "label-info"

            when StatusConstatnt.CPULimit
                @label = "TimeLimitExceeded"
                @label_style = "label-warning"

            when StatusConstatnt.OutputLimit
                @label = "Error"
                @label_style = "label-danger"
            when StatusConstatnt.Error
                @label = "Error"
                @label_style = "label-danger"

            when StatusConstatnt.InvalidCommand
                @label = "InvalidCommand"
                @label_style = "label-danger"

            when StatusConstatnt.Passed
                console.log "AAA", result
                if result.signal? || !result.exit? || result.exit != 0
                    @label = "RuntimeError"
                    @label_style = "label-danger"
                else
                    @label = "Success"
                    @label_style = "label-success"

            when StatusConstatnt.UnexpectedError
                @label = "UnexpectedError(Please report this page...)"
                @label_style = "label-danger"


class UIInfo extends UILabel
    constructor: () ->
        super

        @is_active_tab = true

class UIInfoWithCommandLine extends UIInfo
    constructor: (pattern_name) ->
        super
        @is_open = true
        @wrap = "off"
        @pattern_name = pattern_name
        # used selectable command list
        @allowed_structured_command_line = []   # type: {id: <int>, title: <string>, value: <hash>{<string>: <string>}}

        @is_option_collapsed = $.cookie("sc-ticket-is-compile-option-collapsed-#{@pattern_name}") == 'true'

    # update selectable allowed command line for UI
    set_allowed_structured_command_line: (allowed_command_line) =>
        @allowed_structured_command_line = []

        index = 0
        for key, value of allowed_command_line
            if value?.select?
                # selectable
                for item in value.select
                    t = {}
                    t[key] = if item? then item else ""
                    @allowed_structured_command_line.push {
                        id: index,
                        title: "#{key}#{item}",
                        value: t
                    }
                    index = index + 1
            else
                # only key
                t = {}
                t[key] = null
                @allowed_structured_command_line.push {
                    id: index,
                    title: key,
                    value: t
                }
                index = index + 1

    toggle_option_collapse: () =>
        @is_option_collapsed = !@is_option_collapsed  # invert value to toggle option
        $.cookie("sc-ticket-is-compile-option-collapsed-#{@pattern_name}", @is_option_collapsed)

    should_toggle: () =>
        return @allowed_structured_command_line.length > 0

##########
#
class Result
    constructor: () ->
        @status = null
        @signal = null
        @exit = null

        @stdout = ""
        @stderr = ""
        @cpu = 0
        @memory = 0
        @command = ""

        @cpu_limit = 0
        @memory_limit = 0

    reset: () =>
        @status = null
        @signal = null
        @exit = null
        @stdout = if @stdout?.length > 0 then " " else ""
        @stderr = if @stderr?.length > 0 then " " else ""
        @cpu = 0
        @memory = 0
        @command = ""

    set_result: (result) =>
        @status     = result.status
        @cpu        = result.used_cpu_time_sec
        @memory     = result.used_memory_bytes
        @signal     = result.signal
        @exit       = result.return_code
        #structured_command_line
        @command    = result.command_line
        #system_error_message

        # out and err is encoded by base64, so do decodeing
        @stdout     = if result.out? then atob(result.out) else ""
        @stderr     = if result.err? then atob(result.err) else ""


##########
#
class ProcHolder
    constructor: (default_proc) ->
        @selected = default_proc
        @selected_value = default_proc.title

    set: (raw_proc) =>
        @selected = raw_proc
        @selected_value = raw_proc.title


##########
#
class StructuredCommandLine
    constructor: () ->
        #
        @selected_with_title = []
        #
        @body = []


##########
#
class ResultWithUIandCommandLine extends Result
    constructor: (proc, ui, default_val = null) ->
        super
        @proc = proc
        @ui = ui
        @structured_command_line = new StructuredCommandLine
        @command_line = if default_val?.command_line? then default_val.command_line else ""

        @pattern_name = ui.pattern_name

        #
        @refresh_command_line()

    ##########
    reset: () =>
        super
        @ui.set_ui_label(null)

    ##########
    set_result: (result) =>
        super(result)
        @ui.set_ui_label(this)

    ##########
    refresh_command_line: () =>
        @update_allowed_command_line()
        @load_structured_command_line()

    ##########
    update_allowed_command_line: () =>
        @clear_options()

        allowed_command_line = @proc.selected?.profile?[@pattern_name]?.allowed_command_line

        # update selectable allowed command line for UI
        @ui.set_allowed_structured_command_line(allowed_command_line)

    ##########
    save_structured_command_line: (new_value, do_save_to_cookie) =>
        # console.log "ticket", ticket
        # ticket.compiletime_structured_command_line = []
        # console.log "tickets[selected_tab_index].compiletime_structured_command_line_with_title", new_value

        # copy shown structured command line to ACCUTUAL structured command line
        @structured_command_line.body = (option.value for option in new_value)
        console.log @structured_command_line.body

        # save to cookie related with language_id and version
        if do_save_to_cookie
            $.cookie(@_make_cookie_tag(), JSON.stringify(new_value))
        # console.log JSON.stringify(new_value)

    ##########
    load_structured_command_line: () =>
        @clear_options()

        # console.log "selected!", li, lv
        if $.cookie(@_make_cookie_tag())?
            options = JSON.parse($.cookie(@_make_cookie_tag()))
            # console.log "options #{options}"
            for option in options
                # push only valid options
                for t_opt in @ui.allowed_structured_command_line when t_opt.title == option.title
                    @structured_command_line.selected_with_title.push(t_opt)

        else
            @set_default_option()

    ##########
    generate_structured_command_line: (gen) =>
        @clear_options()
        @structured_command_line.body = gen

        if gen?
            for item in gen
                item_title = ("#{k}#{if v? then v else ''}" for k, v of item)[0]
                # console.log "item_title", item_title
                @structured_command_line.selected_with_title.push(
                    @_search_titled_command(item_title)
                    )

    ##########
    set_default_option: () =>
        allowed_command_line = @proc.selected?.profile?.compile?.allowed_command_line
        unless allowed_command_line?
            return

        @clear_options()

        for key, value of allowed_command_line
            if value?.select?
                for item in value.select
                    if value.default?
                        if ( value.default instanceof Array && item in value.default ) or item == value.default
                            list_item = []
                            for t_opt in @ui.allowed_structured_command_line when t_opt.title == "#{key}#{item}"
                                @structured_command_line.selected_with_title.push(t_opt)

    ##########
    clear_options: () =>
        @structured_command_line.selected_with_title = []
        @structured_command_line.body = []


    ##########
    make_command_line_string: (is_readonly) =>
        dd = @proc.selected?.profile?[@pattern_name]
        if !is_readonly && dd?.command?
            structured_command_line = @structured_command_line?.body
            command_line = @command_line

            return [
                dd.command,
                options_to_s(structured_command_line),
                dd.fixed_command_line,
                escapeshell(command_line)
            ].join(' ')
        else
            return if @command? then @command else dd.file

    ##########
    _make_cookie_tag: () =>
        li = @proc.selected.profile.proc_id
        lv = @proc.selected.profile.proc_version
        return "sc-language-#{li}-#{lv}-options-with-title-#{@pattern_name}"

    ##########
    _search_titled_command: (item) =>
        list_item = i for i in @ui.allowed_structured_command_line when i.title == item
        # console.log "list_item", list_item
        return list_item




class Input extends ResultWithUIandCommandLine
    constructor: (proc, default_val = null) ->
        super(proc, new UIInfoWithCommandLine('run'), default_val)

        @is_running = false

        @stdin = if default_val?.stdin? then default_val.stdin else ""

        if default_val?
            @set_result(default_val.result, default_val)

    reset: () =>
        super
        @ui.set_ui_label(null)

    set_result: (result) =>
        super(result)
        @ui.set_ui_label(this)

    running: () =>
        @is_running = true

    stopped: () =>
        @is_running = false









##########
class CompileResult extends ResultWithUIandCommandLine
    constructor: (proc) ->
        super(proc, new UIInfoWithCommandLine('compile'))




class LinkResult extends ResultWithUIandCommandLine
    constructor: (proc) ->
        super(proc, new UIInfoWithCommandLine('link'))
        @proc = proc
        @ui = new UIInfoWithCommandLine()



class TicketUI
    constructor: () ->
        @is_active_tab = true
        @phase_label_style = ""
        @phase_label = ""




class Ticket
    constructor: (default_proc) ->
        @proc = new ProcHolder(default_proc)
        @do_execution = true
        @is_processing = false
        @phase = null
        @ui = new TicketUI()

        @compile = new CompileResult(@proc)
        @link = new LinkResult(@proc)

        @inputs = []

    ##########
    append_input: (default_val=null) =>
        # set all status of tabs to disable
        for input in @inputs
            input.ui.is_active_tab = false
        # input format
        i = new Input(@proc, default_val)
        @inputs.push(i)

    ##########
    remap_inputs: (inputs_data) =>
        @inputs = []
        for i_data in inputs_data
            @append_input(i_data)
        for input in @inputs
            input.ui.is_active_tab = false
        @inputs.is_active_tab = true

    ##########
    set_phase: (phase) =>
        @phase = phase
        unless phase?
            return

        switch phase
            when PhaseConstatnt.Waiting

                @ui.phase_label = "Waiting..."
                @ui.phase_label_style = "label-info"

            when PhaseConstatnt.NotExecuted
                @ui.phase_label = "NotExecuted"
                @ui.phase_label_style = "label-default"

            when PhaseConstatnt.Compiling
                @ui.phase_label = "Compiling"
                @ui.phase_label_style = "label-warning"

            when PhaseConstatnt.Compiled
                @ui.phase_label = "Compiled"
                @ui.phase_label_style = "label-success"

            when PhaseConstatnt.Linking
                @ui.phase_label = "Linking"
                @ui.phase_label_style = "label-warning"

            when PhaseConstatnt.Linked
                @ui.phase_label = "Linked"
                @ui.phase_label_style = "label-success"

            when PhaseConstatnt.Running
                @ui.phase_label = "Running"
                @ui.phase_label_style = "label-primary"

            when PhaseConstatnt.Finished
                @ui.phase_label = "Finished"
                @ui.phase_label_style = "label-success"

            when PhaseConstatnt.UnexpectedFinished
                @ui.phase_label = "System Error(Please report this page!)"
                @ui.phase_label_style = "label-danger"

    ##########
    reset: () =>
        @set_phase(null)

        @compile.reset()
        @link.reset()

        for input in @inputs
            input.reset()

    ##########
    propagate_proc: (raw_proc) =>
        @proc.set(raw_proc)
        @compile.proc.set(raw_proc)
        @link.proc.set(raw_proc)
        for input in @inputs
            input.proc.set(raw_proc)

    ##########
    refresh_command_line: () =>
        @compile.refresh_command_line()
        #@link.refresh_command_line()
        for input in @inputs
            input.refresh_command_line()


# ==================================================
#
# ==================================================
class ProcProfile
    constructor: (description, hash) ->
        @description = description
        @proc_version = hash.Version
        @is_build_required = hash.IsBuildRequired
        @is_link_independent = hash.IsLinkIndependent
        @source = if hash.Source? then new PhaseDetail(hash.Source) else null
        @compile = if hash.Compile? then new PhaseDetail(hash.Compile) else null
        @link = if hash.Link? then new PhaseDetail(hash.Link) else null
        @run = if hash.Run? then new PhaseDetail(hash.Run) else null

    proc_id: () =>
        return @description.id

    name: () =>
        return @description.name

    runnable: () =>
        return @description.runnable

class ProcDescription
    constructor: (hash) ->
        @id = hash.Id
        @name = hash.Name
        @runnable = hash.Runnable
        @path = hash.Path

class SelectableCommand
    constructor: (hash) ->
        @default = hash.Default
        @select = hash.Select

class PhaseDetail
    constructor: (hash) ->
        @file = hash.File
        @extention = hash.Extention
        @command = hash.Command
        @env = hash.Env
        @extention = null
        @allowed_command_line = hash.AllowedCommandLine
        for key, value of @allowed_command_line
            @allowed_command_line[key] = new SelectableCommand(value)
        f = []
        if hash.FixedCommandLine?
            for cmd in hash.FixedCommandLine
                if cmd.length == 1
                    f.push "#{cmd[0]}"
                else if cmd.length == 2
                    f.push "#{cmd[0]}#{cmd[1]}"
        @fixed_command_line = f.join(' ')

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
            i = 0
            for proc_id, proc_config_unit of gon.proc_table
                description = new ProcDescription(proc_config_unit.Description)
                proc_profile_table = proc_config_unit.Versioned
                for proc_version, proc_profile of proc_profile_table
                    $scope.procs.push {
                        id: i,
                        value: {proc_id: proc_id, proc_version: proc_version},
                        title: "#{description.name} - #{proc_version}",
                        group: description.name,
                        profile: new ProcProfile(description, proc_profile)
                    }
                    i = i + 1

        # Language Processor List...
        $scope.procs = []
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
        #
        $scope.selected_tab_index = 0

        $scope.change_ticket_tab = (index) =>
            $scope.selected_tab_index = index


        ########################################
        #
        $scope.selected_input_tab_index = 0

        $scope.change_input_tab = (index) =>
            $scope.selected_input_tab_index = index


        ########################################
        # change editor highlight by selected item
        $scope.$watchCollection(
            'tickets[selected_tab_index].proc.selected',
            (new_value, old_value) =>
                # console.log old_value, new_value
                if ! new_value?
                    $scope.submit_able = false
                    return
                $scope.submit_able = true

                (new CodemirrorEditor).set_highlight(new_value.title)
                # console.log new_value
                # console.log $scope.selected_tab_index
                if $scope.do_save_cookie
                    $.cookie("sc-editor-cached-language-title", new_value.title)

                if new_value == old_value
                    return

                selected_ticket = $scope.tickets[$scope.selected_tab_index]
                old_proc_value = selected_ticket?.proc.selected_value # proc.selected is change automatialy(by Angular), but proc.selected_value contains old value!

                console.log new_value
                selected_ticket.propagate_proc(new_value)

                # console.error "changed", $scope.tickets[$scope.selected_tab_index].current_proc_value, new_value
                # change if diffed
                if new_value.value != old_proc_value
                    selected_ticket.refresh_command_line()
        )


        #
        $scope.$watchCollection(
            'tickets[selected_tab_index].compile.structured_command_line.selected_with_title',
            (new_value)=>
                unless new_value?
                    return

                ticket = $scope.tickets[$scope.selected_tab_index]
                ticket.compile.save_structured_command_line(new_value, $scope.do_save_cookie)
        )

        # TODO: add watch for link

        #
        $scope.$watchCollection(
            'tickets[selected_tab_index].inputs[selected_input_tab_index].structured_command_line.selected_with_title',
            (new_value)=>
                unless new_value?
                    return

                input = $scope.tickets[$scope.selected_tab_index].inputs[$scope.selected_input_tab_index]
                input.save_structured_command_line(new_value, $scope.do_save_cookie)
        )


        ##########
        $scope.select_default_language = () =>
            try
                if $.cookie("sc-editor-cached-language-title")?
                    cached_proc_title = $.cookie("sc-editor-cached-language-title")
                    found_index = null
                    for proc, index in $scope.procs
                        if cached_proc_title == proc.title
                            found_index = index
                            break
                    if found_index?
                        return $scope.procs[found_index]
                    else
                        throw "proc index not found"
                else
                    # set default...
                    # find c++(gcc)
                    default_proc = p for p in $scope.procs when p.profile.proc_id == 100 && p.profile.proc_version == "4.8.2"
                    return default_proc ? $scope.procs[0]
            catch error
                return $scope.procs[0] # default value



        ########################################
        #
        $scope.append_ticket = () =>
            for ticket in $scope.tickets
                ticket.ui.is_active_tab = false

            default_proc = $scope.select_default_language()

            # ticket format
            ticket = new Ticket(default_proc)
            $scope.tickets.push(ticket)

            # the ticket must has inputs at least one.
            ticket.append_input()

        ########################################
        #
        $scope.force_set_ticket_tab_index = (ticket_index) =>
            for ticket in $scope.tickets
                ticket.ui.is_active_tab = false
            $scope.tickets[ticket_index].ui.is_active_tab = true


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
            #####
            $scope.is_running = true
            $scope.reset_entry()

            # console.log "submit all!"
            source_code = (new CodemirrorEditor).get_value()
            # console.log source_code

            #####
            # !!!! construct POST data
            raw_submit_data = {
                description: "",
                visibility: $scope.visibility,
                source_codes: [
                    source_code
                ],
                tickets: ({
                    proc_id: 100,
                    proc_version: "!=head",
                    do_execution: ticket.do_execution,
                    compile: {
                        structured_command_line: ticket.compile.structured_command_line.body,
                    },
                    link: {
                        structured_command_line: ticket.link.structured_command_line.body,
                    },
                    inputs: ({
                        command_line: input.command_line,
                        structured_command_line: input.structured_command_line.body,
                        stdin: input.stdin
                    } for input in ticket.inputs)
                } for ticket in $scope.tickets)
            }


            submit_data = {
                api_version: 1,
                type: "json",
                value: JSON.stringify(raw_submit_data)
            }
            console.log submit_data

            # submit!
            $.post("/api/source", submit_data, "json")
                .done (data) =>
                    $rootScope.$apply () =>
                        if data.is_error
                            alert("Error[1](please report): #{data.message}")
                            $scope.finish_ticket()
                        else
                            $scope.wait_entry_for_update(data.entry_id, data.ticket_ids)
                .fail () =>
                    $rootScope.$apply () =>
                        alert("Failed[1]")
                        $scope.finish_ticket()


        ########################################
        # phase 2
        $scope.wait_entry_for_update = (entry_id, ticket_ids, with_init = false, set_source = false) =>
            $scope.is_running = true

            $.get("/api/entry/#{entry_id}", "json")
                .done (data) =>
                    $rootScope.$apply () =>
                        if data.is_error
                            alert("Error[2](please report): #{data.message}")
                            $scope.finish_ticket()
                        else
                            $scope.current_entry_id = entry_id

                            # make parmlink button
                            $scope.current_entry_target_url = "http://test.sc.yutopp.net/entries/#{$scope.current_entry_id}"
                            text = "[ProcGarden]⊂二二二（ ◔⊖◔）二⊃"
                            tweet_url = "https://platform.twitter.com/widgets/tweet_button.html?url=#{$scope.current_entry_target_url}&text=#{text}"
                            $scope.current_entry_tweet = $sce.trustAsResourceUrl(tweet_url)

                            console.log "Entry Loaded: " + JSON.stringify(data)

                            if with_init
                                # make tickets
                                $scope.tickets = []
                                for i in [0...(ticket_ids.length)]
                                    $scope.append_ticket()
                                $scope.force_set_ticket_tab_index(0)

                                # load source code
                                if set_source
                                    (new CodemirrorEditor).set_value(data.code.source)

                                unless set_source
                                    $scope.visibility = data.visibility

                            # console.log data.ticket.num
                            # apply for all tickets
                            for i in [0...ticket_ids.length]
                                console.log i, ticket_ids[i]
                                # set processing flag
                                $scope.tickets[i].is_processing = true
                                # make handler for get ticket data per ticket
                                $scope.wait_ticket_for_update(i, ticket_ids[i], with_init)
                .fail () =>
                    $rootScope.$apply () =>
                        alert("Failed[2]")
                        $scope.finish_ticket(ticket_index)


        ########################################
        # phase 3
        $scope.wait_ticket_for_update = (ticket_index, ticket_id, with_init = false) =>
            $.get("/api/ticket/#{ticket_id}", "json")
                .done (data) =>
                    # console.log( "Data Loaded: " + JSON.stringify(data) )
                    $rootScope.$apply () =>
                        if data.is_error
                            alert("Error[3](please report): #{data.message}")
                            $scope.finish_ticket()
                        else
                            ticket_model = data.ticket
                            console.log "Ticket Loaded: " + JSON.stringify(ticket_model)

                            if with_init
                                $scope.load_ticket_profile(ticket_index, ticket_model)

                            $scope.bind_ticket_data(ticket_index, ticket_id, ticket_model)
                            $scope.tickets[ticket_index].set_phase(ticket_model["phase"])

                            console.log "ticket", ticket_index, ticket_model

                            if ticket_model["is_running"]
                                # set processing flag
                                $scope.tickets[ticket_index].is_processing = true
                                if $scope.selected_tab_index == ticket_index
                                    setTimeout( (() => $scope.wait_ticket_for_update(ticket_index, ticket_id) ), 200 ) # recursive call
                                else
                                    setTimeout( (() => $scope.wait_ticket_for_update(ticket_index, ticket_id) ), 2000 ) # recursive call
                            else
                                # set processing flag
                                $scope.finish_ticket(ticket_index)
                .fail () =>
                    $rootScope.$apply () =>
                        alert("Failed[3]")
                        $scope.finish_ticket()


        ########################################
        #
        $scope.bind_ticket_data = (ticket_index, ticket_id, ticket_model) =>
            ######
            # build
            if ticket_model.compile_state?
                $scope.tickets[ticket_index].compile.set_result(ticket_model.compile_state)

            if ticket_model.link_state?
                $scope.tickets[ticket_index].link.set_result(ticket_model.link_state)


            # console.log data.phase, @PhaseRunning

            ######
            # run
            # -> update per input
            if ticket_model.phase >= @PhaseRunning
                if ticket_model.run_states?
                    for run_state in ticket_model.run_states
                        console.log run_state
                        # console.log "out => #{result.record.out}, #{ticket_index} / #{input_index}"
                        # console.log "!=> #{$scope.tickets[ticket_index].inputs[input_index].stdout}"
                        #
                        $scope.tickets[ticket_index].inputs[run_state.index].stopped
                        $scope.tickets[ticket_index].inputs[run_state.index].set_result(run_state)

                        #else
                        #    $scope.tickets[ticket_index].inputs[input_index].running


                    #
                    #$scope.tickets[ticket_index].inputs[input_index].stdin = input.stdin
                    #$scope.tickets[ticket_index].inputs[input_index].runtime_command_line = input.command_line
                    #$scope.tickets[ticket_index].inputs[input_index].runtime_structured_command_line = input.structured_command_line


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
        $scope.load_ticket_profile = (ticket_index, ticket_data) =>
            language_id = ticket_data.language_id
            language_proc_version = ticket_data.language_proc_version

            ticket = $scope.tickets[ticket_index]

            found_proc = p for p in $scope.procs when p.profile.proc_id == language_id && p.profile.proc_version == language_proc_version
            unless found_proc?
                # the Proc of this ticket is already unsupported, so make a DUMMY proc profile
                # Error....
                # console.log "error... : found_proc?"
                # make minimum details...
                dummy_description = new ProcDescription({
                    Id: 0
                    Name: if ticket_data.language_label? then ticket_data.language_label else "???",
                    Runnable: true,
                    Path: "???"
                })

                profile = new ProcProfile(dummy_description, {
                    Version: "UNSUPPORTED",
                    IsBuildRequired: true,
                    IsLinkIndependent: true,
                    Source: {
                        File: "???"
                        Extention: "???"
                    },
                    Compile: {
                        File: "???"
                        Extention: "???"
                    },
                    Link: {
                        File: "???"
                        Extention: "???"
                    },
                    Run: {
                        File: "???"
                        Extention: "???"
                    }
                })

                found_proc = {
                    value: "???",
                    title: "#{detail.name}(unsupported in ProcGarden)",
                    group: "???",
                    profile: profile
                }

                ticket.do_execution = true

            #
            ticket.propagate_proc(found_proc)

            # inputs number error correction
            if ticket_data.inputs?
                ticket.remap_inputs(ticket_data.inputs)

            #
            ticket.compile.update_allowed_command_line()
            ticket.compile.generate_structured_command_line(ticket_data.compiletime_structured_command_line)

            #
            #ticket.link.update_allowed_command_line()
            #ticket.link.generate_structured_command_line(ticket_data.link_structured_command_line)

            #
            for input, index in ticket.inputs
                input.update_allowed_command_line()
                input.generate_structured_command_line(ticket_data.inputs[index].structured_command_line)



        ########################################
        # logics are same as RunnerNodeServers
        #
        $scope.make_compile_command_line = (ticket_index, is_readonly = false) =>
            return $scope.tickets[ticket_index].compile.make_command_line_string(is_readonly)


        $scope.make_link_command_line = (ticket_index, is_readonly = false) =>
            ticket = $scope.tickets[ticket_index]
            dd = ticket.proc.selected.profile.link
            if dd.command?
                structured_command_line =
                    ticket.link.structured_command_line?.body
                command_line = ''

                command = [dd.command, options_to_s(structured_command_line), dd.fixed_command_line, escapeshell(command_line)].join(' ')
                return command
            else
                return if ticket.link.command? then ticket.link.command else dd.file


        $scope.make_run_command_line = (ticket_index, input_index, is_readonly = false) =>
            return $scope.tickets[ticket_index].inputs[input_index].make_command_line_string(is_readonly)

        #
        $scope.dc = (num) =>
            num.toString().replace(/(\d)(?=(\d\d\d)+(?!\d))/g, '$1,')

        $scope.mem_dc = (num) ->
            $scope.dc(num/1024)

    ]
)





# ==================================================
# ==================================================
# ==================================================
# ==================================================
#
ProcGardenApp.controller(
    'Languages',
    ['$scope', ($scope) =>
        console.log JSON.stringify(gon.proc_table)
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
