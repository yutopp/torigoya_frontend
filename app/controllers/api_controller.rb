require 'torigoya_kit'
require 'mongoid/grid_fs'
require 'tempfile'
require 'digest/md5'
require 'securerandom'

class ApiController < ApplicationController
  include Cages
  include ExecutionTaskWorker
  include Api

  protect_from_forgery except: [:get_cage_nodes]

  #
  def post_source
    api_version = ApiUtil.get_api_version(params)
    result = case api_version
             when 1
               Api::PostSourceV1.execute(params)
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
    # TODO: change
    render :json => result
  end

  #
  def get_entry
    entry = Entry.find(params["entry_id"])
    result = {
      :is_error => false,
      :entry => entry.as_document,
      :ticket_ids => entry.tickets.map {|t| t.id.to_s },
    }

  rescue => e
    result = {
      :is_error => true,
      :message => e.to_s
    }

  ensure
    render :json => result
  end


  class Offsets
    def initialize(out, err)
      @out = out
      @err = err
    end
    attr_reader :out, :err
  end


  def get_offsets(data)
    out = ApiUtil.validate_type(data, 'out', Integer)
    err = ApiUtil.validate_type(data, 'err', Integer)

    return Offsets.new(out, err)
  end

  def get_unit_offsets(value, key)
    unless value.nil?
      if value.has_key?(key)
        return get_offsets(value[key])
      end
    end

    return nil
  end

  def get_array_offsets(value, key, length)
    unless value.nil?
      if value.has_key?(key)
        # NOTE: 2048 offsets of inputs can be accepted.
        offsets = ApiUtil.validate_array(value, key, 0, 2048)
        return offsets.map {|off| if off.nil? then nil else get_offsets(off) end}
      end
    end

    return length.times.map {|n| nil}
  end

  def get_ticket
    api_version = ApiUtil.get_api_version(params)
    result = case api_version
             when 1
               p "----"
             else
               raise "version #{api_version} is not supported."
             end

    # ========================================
    # value
    # ========================================
    value = ApiUtil.extract_value(params)

    ticket = Ticket.find(params["ticket_id"]).as_document

    if ticket.has_key?("compile_state")
      convert_binary_array_to_base64_string(ticket["compile_state"],
                                            get_unit_offsets(value, 'compile')
                                            )
    end

    if ticket.has_key?("link_state")
      convert_binary_array_to_base64_string(ticket["link_state"],
                                            get_unit_offsets(value, 'link')
                                            )
    end

    if ticket.has_key?("run_states")
      offsets = get_array_offsets(value, 'run', ticket["run_states"].length)
      if offsets.length != ticket["run_states"].length
        raise "offset length is invalid. #{offsets.length} / #{ticket["run_states"].length}"
      end

      ticket["run_states"].each_with_index do |s, i|
        convert_binary_array_to_base64_string(s, offsets[i])
      end
    end

    remove_extra_values(ticket)

    result = {
      :is_error => false,
      :ticket => ticket
    }

  rescue => e
    result = {
      :is_error => true,
      :message => e.to_s
    }

    Rails.logger.error ">>>>>>>>>>>>> class => #{e.class}\n!! detail => #{e}\n!! trace => #{$@.join("\n")}"

  ensure
    render :json => result.to_json
  end


  def get_cage_nodes
    result = {
      :is_error => false,
      :nodes => get_nodes_info()
    }

  rescue => e
    result = {
      :is_error => true,
      :message => e.to_s
    }

  ensure
    render :json => result.to_json
  end


  private
  def convert_binary_array_to_base64_string(state, offsets)
    if state.has_key?("out")
      from = if offsets.nil? then 0 else offsets.out end
      to = state["out"].length
      if from < 0 || from > to
        raise "invalid offset[out]"
      end
      range = state["out"][from...to] # [from, to)
      state["out"] = Base64.strict_encode64(range.inject(""){|all, s| all + s.data})
      state["out_until"] = to
    end

    if state.has_key?("err")
      from = if offsets.nil? then 0 else offsets.err end
      to = state["err"].length
      if from < 0 || from > to
        raise "invalid offset[err]"
      end
      range = state["err"][from...to] # [from, to)
      state["err"] = Base64.strict_encode64(state["err"].inject(""){|all, s| all + s.data})
      state["err_until"] = to
    end

    remove_extra_values(state)
  end

  def remove_extra_values(data)
    if data.has_key?('_id')
      data.delete('_id')
    end

    if data.has_key?('_type')
      data.delete('_type')
    end
  end
end
