require 'torigoya_kit'
require 'mongoid/grid_fs'
require 'tempfile'

class ApiController < ApplicationController
  include ExecutionTaskWorker

  def post_source
    unless params.has_key?("api_version")
      raise "api_version was not given"
    end
    api_version = params["api_version"].to_i
    result = case api_version
             when 1
               post_source_v1
             else
               raise "version #{api_version} is not supported."
             end

  rescue => e
    result = {
      :is_error => true,
      :message => e.to_s
    }

    Rails.logger.error ">>>>>>>>>>>>> class => #{e.class}\n!! detail => #{e}\n!! trace => #{$@.join("\n")}"

  ensure
    render :json => result
  end


  def get_entry
    entry = Entry.find(params["entry_id"]).as_document
    result = {
      :is_error => false,
      :entry => entry
    }
#    Rails.logger.error params
#    Rails.logger.error entry

  rescue => e
    result = {
      :is_error => true,
      :message => e.to_s
    }

  ensure
    render :json => result
  end


  def get_ticket
    ticket = Ticket.find(params["ticket_id"]).as_document
    convert_binary_array_to_base64_string(ticket["compile_state"]) if ticket.has_key?("compile_state")
    convert_binary_array_to_base64_string(ticket["link_state"]) if ticket.has_key?("link_state")
    ticket["run_states"].each {|s| convert_binary_array_to_base64_string(s)} if ticket.has_key?("run_states")

    result = {
      :is_error => false,
      :ticket => ticket
    }

  rescue => e
    result = {
      :is_error => true,
      :message => e.to_s
    }

#    Rails.logger.error ">>>>>>>>>>>>> class => #{e.class}\n!! detail => #{e}\n!! trace => #{$@.join("\n")}"

  ensure
    render :json => result.to_json
  end


  private
  def convert_binary_array_to_base64_string(state)
    state["out"] = Base64.strict_encode64(state["out"].inject(""){|all, s| all + s.data}) if state.has_key?("out")
    state["err"] = Base64.strict_encode64(state["err"].inject(""){|all, s| all + s.data}) if state.has_key?("err")
  end



  private
  def validate_type(base, key, type)
    unless base.has_key?(key)
      raise "#{key} was not given"
    end
    unless base[key].is_a?(type)
      raise "type of #{key} must be #{type} (but #{base[key].class})"
    end

    return base[key]
  end

  def validate_array(base, key, min, max)
    validate_type(base, key, Array)

    unless base[key].length >= min && base[key].length <= max
      raise "a number of #{key} must be [#{min}, #{max}]"
    end

    return base[key]
  end

  def parse_execution_settings(base, tag)
    command_line = if base.has_key?("command_line")
                     validate_type(base, "command_line", String)
                   else
                     ""
                   end
    structured_command_line = validate_type(base, "structured_command_line", Array)

    return TorigoyaKit::ExecutionSetting.new(command_line,
                                             structured_command_line,
                                             5,   # 5sec
                                             1 * 1024 * 1024 * 1024 # 1GB
                                             )
  end

  def post_source_v1
    # ========================================
    # type
    # ========================================
    unless params.has_key?("type")
      raise "type was not given"
    end
    unless params["type"] == "json"
      raise "only json format is supported"
    end

    # ========================================
    # value
    # ========================================
    value = JSON.parse(validate_type(params, "value", String))

#    Rails.logger.info "VALUE => " + value.to_s


    ### ========================================
    ### description
    ### ========================================
    description = validate_type(value, "description", String)

    ### ========================================
    ### visibility
    ### ========================================
    visibility = validate_type(value, "visibility", Integer)

    # ========================================
    # user id
    # ========================================
    #user_id = if user_signed_in? then current_user.id.to_s then nil end
    user_id = nil

    ### ========================================
    ### source code
    ### ========================================
    source_data = validate_array(value, "source_codes", 1, 1)    # currently only one file is accepted
    source_codes = source_data.map do |code|
      # no filename => nil
      next TorigoyaKit::SourceData.new(nil, code)
    end

    entry = Entry.new(:owner_user_id => user_id,
                      :revision => "",
                      :visibility => visibility,
                      )

    grid_fs = Mongoid::GridFs
    source_data.each do |code|
      begin
        # TODO: support multi files
        file = Tempfile.new('procgarden_frontend')
        file.write(code)
        file.close

        f = grid_fs.put(file.path)
        code = entry.codes.build(:file_id => f.id,
                                 :file_name => "source",
                                 :type => :native,
                                 )
        code.save!

      ensure
        file.unlink unless file.nil?
      end
    end


    ### ========================================
    ### tickets
    ### ========================================
    tickets_data = validate_array(value, "tickets", 1, 10)
    tickets = tickets_data.map do |ticket|
      proc_id = validate_type(ticket, "proc_id", Integer)
      proc_version = validate_type(ticket, "proc_version", String)
      do_execution = validate_type(ticket, "do_execution", Boolean)

      ##### ========================================
      ##### compile
      ##### ========================================
      compile = if ticket.has_key?("compile")
                  parse_execution_settings(ticket["compile"], :compile)
                else
                  nil
                end

      ##### ========================================
      ##### link
      ##### ========================================
      link = if ticket.has_key?("link")
               parse_execution_settings(ticket["link"], :link)
             else
               nil
             end

      ##### ========================================
      ##### build inst
      ##### ========================================
      build_inst = unless compile.nil? && link.nil?
                     TorigoyaKit::BuildInstruction.new(compile, link)
                   else
                     nil
                   end

      ##### ========================================
      ##### inputs
      ##### ========================================
      inputs_data = validate_array(ticket, "inputs", 1, 10)
      inputs = inputs_data.map.with_index do |input, index|
        stdin = TorigoyaKit::SourceData.new(index.to_s, validate_type(input, "stdin", String))
        run = parse_execution_settings(input, :run)
        next TorigoyaKit::Input.new(stdin, run)
      end


      if do_execution
        ##### ========================================
        ##### run inst
        ##### ========================================
        run_inst = TorigoyaKit::RunInstruction.new(inputs)

        next TorigoyaKit::Ticket.new("base_name", proc_id, proc_version, source_codes, build_inst, run_inst)

      else
        next {
          proc_id: proc_id,
          proc_version: proc_version,
          compile_inst: compile,
          link_inst: link,
          inputs: inputs
        }
      end
    end # tickets_data.map

    #
    tickets.each do |t|
      if t.is_a?(TorigoyaKit::Ticket)
        # do execution
        m = entry.tickets.build(:is_running => true,
                                :processed => false,
                                :do_execute => true,
                                :proc_id => t.proc_id,
                                :proc_version => t.proc_version,
                                :proc_label => "",
                                :phase => Phase::Waiting
                                )
        m.save!

        execute_and_update_ticket(t, m)

      else
        # do NOT execution
        m = entry.tickets.build(:is_running => false,
                                :processed => true,
                                :do_execute => false,
                                :proc_id => t.proc_id,
                                :proc_version => t.proc_version,
                                :proc_label => "",
                                :phase => Phase::NotExecuted
                                )
        m.save!
      end
    end

    entry.save!

    return {
      :entry_id => entry.id.to_s,
      :ticket_ids => entry.tickets.map {|t| t.id.to_s },
      :is_error => false
    }
  end

end
