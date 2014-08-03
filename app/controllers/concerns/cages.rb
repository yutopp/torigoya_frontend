require 'torigoya_kit'
require 'singleton'

module Cages
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
  def exec_ticket_with_stream(ticket, platform = :linux, &block)
    session = Instances.instance.pick(platform)
    session.exec_ticket_with_stream(ticket, &block)
  end
  module_function :exec_ticket_with_stream

  #
  class Instances
    include Singleton

    def pick(platform = :linux)
      # TODO: fix it
      return TorigoyaKit::Session.new(Rails.application.secrets.boot_cage_addr,
                                      Rails.application.secrets.boot_cage_port)
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
