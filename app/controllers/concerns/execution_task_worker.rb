require 'torigoya_kit'
require 'singleton'

module ExecutionTaskWorker
  def execute_and_update_ticket(ticket, ticket_model)
    Worker.instance.add(ticket, ticket_model)
  end
  module_function :execute_and_update_ticket

  #
  module Errors
    class UnsupportedLangError < StandardError
    end

    class UnexpectedError < StandardError
    end

    class RunnerError < StandardError
    end

    class CompilationError < StandardError
    end

    class LinkError < StandardError
    end

    class EntryNotFoundError < StandardError
    end

    class OpenPrivateEntryError < StandardError
    end
  end

  #
  class Worker
    include Singleton

    ThreadNum = 5
    def initialize
      @tickets = Queue.new

      @workers = (0...ThreadNum).map do |id|
        Thread.start do
          Rails.logger.debug "Worker / thread-#{id.to_s}"

          loop do
            begin
              ticket, model = @tickets.pop     # pop ticket data from task queue
              Rails.logger.debug ticket

              # run!
              RunFlow.run(ticket, model)

            rescue Errors::RunnerError => e
              Rails.logger.error "Worker / RunnerError in Worker thread. ticket[id=#{model.id}]. \n!! detail => #{e}\n!! trace => #{$@.join("\n")}"
              #ticket.error!

            rescue Encoding::CompatibilityError, Encoding::UndefinedConversionError => e
              Rails.logger.error "Worker / Encoding error in Worker thread. ticket[id=#{model.id}]. \n!! detail => #{e}\n!! trace => #{$@.join("\n")}"
              # out/err will contains invalid string sequenses, so remove them
              model.compile_state = nil
              model.link_state = nil
              model.embeds_many = nil

            rescue => e
              Rails.logger.error "Worker / unexpected in Worker thread. ticket[id=#{model.id}]. \n!! class => #{e.class}\n!! detail => #{e}\n!! trace => #{$@.join("\n")}"
              #ticket.error!

            ensure
              model.is_running = false
              model.save!
              #ticket.ensure!
              #ticket.show
              Rails.logger.debug "Worker / finished work!"
            end
          end # loop
        end # Thread.start
      end # map

      ##
      #start_resume_incomplete_tickets_thread()
    end # def initialize

    def add(ticket, ticket_model)
      @tickets.push([ticket, ticket_model])
    end # def add
  end

  class RunFlow
    def self.run(ticket, model)
      Rails.logger.debug "RUN! RUN!"

      memo = {
        :compile => {},
        :link => {},
        :run => {},
      }

      Cages::exec_ticket_with_stream(ticket) do |res|
        if res.is_a?(TorigoyaKit::StreamOutputResult) || res.is_a?(TorigoyaKit::StreamExecutedResult)
          #
          case res.mode
          when TorigoyaKit::ResultMode::CompileMode
            if memo[:compile][res.index].nil?
              # change phase
              model.phase = Phase::Compiling
              # create state info
              memo[:compile][res.index] = CompileState.new(:index => res.index)
              model.compile_state = memo[:compile][res.index]
            end

          when TorigoyaKit::ResultMode::LinkMode
            if memo[:link][res.index].nil?
              # change phase
              model.phase = Phase::Linking
              #
              memo[:link][res.index] = LinkState.new(:index => res.index)
              model.link_state = memo[:link][res.index]
            end

          when TorigoyaKit::ResultMode::RunMode
            if memo[:run][res.index].nil?
              # change phase
              model.phase = Phase::Running
              #
              memo[:run][res.index] = RunState.new(:index => res.index)
              model.run_states << memo[:run][res.index]
            end
          end

          #
          tag = case res.mode
                when TorigoyaKit::ResultMode::CompileMode
                  :compile
                when TorigoyaKit::ResultMode::LinkMode
                  :link
                when TorigoyaKit::ResultMode::RunMode
                  :run
                end

          #
          if res.is_a?(TorigoyaKit::StreamOutputResult)
            # stdout/stderr
            case res.output.fd
            when TorigoyaKit::StreamOutput::StdoutFd
              # stdout
              memo[tag][res.index].push(out: BSON::Binary.new(res.output.buffer.force_encoding("ASCII-8BIT")))

            when TorigoyaKit::StreamOutput::StderrFd
              # stderr
              memo[tag][res.index].push(err: BSON::Binary.new(res.output.buffer.force_encoding("ASCII-8BIT")))
            end

          elsif res.is_a?(TorigoyaKit::StreamExecutedResult)
            # result
            memo[tag][res.index].used_cpu_time_sec      = res.result.used_cpu_time_sec
            memo[tag][res.index].used_memory_bytes      = res.result.used_memory_bytes
            memo[tag][res.index].signal                 = res.result.signal
            memo[tag][res.index].return_code            = res.result.return_code
            memo[tag][res.index].command_line           = res.result.command_line
            memo[tag][res.index].status                 = res.result.status
            memo[tag][res.index].system_error_message   = res.result.system_error_message
          end

        elsif res.is_a?(TorigoyaKit::StreamSystemError)
          # error
          raise res.message

        else
          # unexpected
          raise "Unexpected error: unknown message was recieved (#{res.class})"
        end

        model.save!

        #Rails.logger.debug res.to_s
      end # do |res|

      model.phase = Phase::Finished
      model.save!

    rescue => e
      model.phase = Phase::Error
      model.save!
      raise

    end # def
  end

  class Phase
    Waiting = 0
    NotExecuted = 10
    Compiling = 200
    Compiled = 250
    Linking = 280
    Linked = 281
    Running = 300
    Finished = 400
    Error = 401
  end
end
