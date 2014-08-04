require 'torigoya_kit'
require 'singleton'

module Cages
  #
  def get_proc_table(platform = :linux)
    # TODO: implement cache
    h = ProcTableHolder.instance
    unless h.having?
      session = Instances.instance.pick(platform)
      pt = session.get_proc_table
      h.set pt
    end

    return h.table
  end
  module_function :get_proc_table

  #
  def get_nodes_info
    h = Instances.instance
    return h.list()
  end
  module_function :get_nodes_info

  #
  def exec_ticket_with_stream(ticket, platform = :linux, &block)
    session = Instances.instance.pick(platform)
    session.exec_ticket_with_stream(ticket, &block)
  end
  module_function :exec_ticket_with_stream

  #
  class Instances
    include Singleton

    def list()
      return [
              {
                addr: Rails.application.secrets.boot_cage_addr,
                port: Rails.application.secrets.boot_cage_port,
              }
             ]
    end

    def pick(platform = :linux)
      # TODO: fix it
      return TorigoyaKit::Session.new(list()[0][:addr], list()[0][:port])
    end
  end

  #
  class ProcTableHolder
    include Singleton

    def having?
      return @table != nil
    end

    def set(pt)
      @table = pt
    end

    def table
      return @table
    end
  end
end
