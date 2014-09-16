require 'torigoya_kit'
require 'mongoid/grid_fs'
require 'tempfile'
require 'digest/md5'
require 'securerandom'

module Api
  class PostSourceV1
    include ExecutionTaskWorker
    include Cages

    def self.parse_execution_settings(base, tag)
      command_line = if base.has_key?("command_line")
                       ApiUtil.validate_type(base, "command_line", String)
                     else
                       ""
                     end
      structured_command_line = ApiUtil.validate_type(base, "structured_command_line", Array)

      return TorigoyaKit::ExecutionSetting.new(command_line,
                                               structured_command_line,
                                               5,   # 5sec
                                               1 * 1024 * 1024 * 1024 # 1GB
                                               )
    end


    class ExecutableTicketInfo
      def initialize(index, kit)
        @index = index    # int
        @kit = kit        # TorigoyaKit::Ticket
      end
      attr_reader :index, :kit

      def proc_id
        return @kit.proc_id
      end

      def proc_version
        return @kit.proc_version
      end
    end

    class NoExecutableTicketInfo
      def initialize(index, proc_id, proc_version, compile_inst, link_inst)
        @index = index
        @proc_id = proc_id
        @proc_version = proc_version
        @compile_inst = compile_inst
        @link_inst = link_inst
      end
      attr_reader :index, :proc_id, :proc_version
      attr_reader :compile_inst, :link_inst
    end

    def self.load_tickets_info(value, source_codes)
      tickets_data = ApiUtil.validate_array(value, "tickets", 1, 10)
      tickets = tickets_data.map.with_index do |ticket, index|
        proc_id = ApiUtil.validate_type(ticket, "proc_id", Integer)
        proc_version = ApiUtil.validate_type(ticket, "proc_version", String)
        do_execution = ApiUtil.validate_type(ticket, "do_execution", Boolean)

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
        inputs_data = ApiUtil.validate_array(ticket, "inputs", 1, 10)
        inputs = inputs_data.map.with_index do |input, index|
          stdin = TorigoyaKit::SourceData.new(index.to_s,
                                              ApiUtil.validate_type(input, "stdin", String)
                                              )
          run = parse_execution_settings(input, :run)
          next TorigoyaKit::Input.new(stdin, run)
        end

        #
        if do_execution
          ##### ========================================
          ##### run inst
          ##### ========================================
          run_inst = TorigoyaKit::RunInstruction.new(inputs)

          base_name = Digest::MD5.hexdigest("#{proc_id}/#{proc_version}/#{source_codes}/#{Time.now}") + SecureRandom.hex(16)

          #
          kit = TorigoyaKit::Ticket.new(base_name, proc_id, proc_version, source_codes, build_inst, run_inst)
          next ExecutableTicketInfo.new(index, kit)

        else
          next NoExecutableTicketInfo.new(index, proc_id,  proc_version, compile, link)
        end
      end # tickets_data.map

      return tickets
    end

    def self.execute(params)
      # ========================================
      # value
      # ========================================
      value = ApiUtil.extract_value(params)
      if value.nil?
        raise "value was not given"
      end
      #    Rails.logger.info "VALUE => " + value.to_s


      ### ========================================
      ### description
      ### ========================================
      description = ApiUtil.validate_type(value, "description", String)

      ### ========================================
      ### visibility
      ### ========================================
      visibility = ApiUtil.validate_type(value, "visibility", Integer)

      # ========================================
      # user id
      # ========================================
      #user_id = if user_signed_in? then current_user.id.to_s then nil end
      user_id = nil

      ### ========================================
      ### source code
      ### ========================================
      source_data = ApiUtil.validate_array(value, "source_codes", 1, 1)    # currently only one file is accepted
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
      tickets_info = load_tickets_info(value, source_codes)

      #
      proc_table = Cages.get_proc_table()
      language_tags = tickets_info.map do |t|
        if proc_table.has_key?(t.proc_id)
          next "#{proc_table[t.proc_id]['Description']['Name']}[#{t.proc_version}]"
        else
          next nil
        end
      end
      entry.language_tags = language_tags.compact.uniq

      #
      tickets_info.each do |t|
        if t.is_a?(ExecutableTicketInfo)
          # do execution
          model = entry.tickets.build(:index => t.index,
                                      :is_running => true,
                                      :processed => false,
                                      :do_execute => true,
                                      :proc_id => t.proc_id,
                                      :proc_version => t.proc_version,
                                      :proc_label => "",
                                      :phase => Phase::Waiting
                                      )
          model.save!

          # execute!
          ExecutionTaskWorker.execute_and_update_ticket(t.kit, model)

        else
          # do NOT execution
          model = entry.tickets.build(:index => t.index,
                                      :is_running => false,
                                      :processed => true,
                                      :do_execute => false,
                                      :proc_id => t.proc_id,
                                      :proc_version => t.proc_version,
                                      :proc_label => "",
                                      :phase => Phase::NotExecuted
                                      )
          model.save!
        end
      end # tickets.each

      entry.save!

      return {
        :entry_id => entry.id.to_s,
        :ticket_ids => entry.tickets.map {|t| t.id.to_s },
        :is_error => false
      }
    end
  end # clsss PostSourceV1
end # module Api
