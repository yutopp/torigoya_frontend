require 'torigoya_kit'
require 'singleton'

module Cages
  # returns proc table data
  def get_proc_table(platform = :linux)
    h = ProcTableHolder.instance
    unless h.cached?
      load_proc_table_from_db(platform)
    end

    return h.table
  end
  module_function :get_proc_table

  #
  def update_proc_table(platform = :linux)
    update_proc_table_from_node()
    load_proc_table_from_db()
  end
  module_function :update_proc_table


  #
  def update_proc_table_from_node(platform = :linux)
    # load data from a remote node
    session = Instances.instance.pick(platform)
    pt = session.get_proc_table

    store_proc_table_to_db(pt)
  end
  module_function :update_proc_table_from_node

  #
  def store_proc_table_to_db(pt)
    tmp = {}
    LangProc.all.each do |lp|
      tmp[lp.id] = { :proc_id => lp.proc_id, :version => lp.version }
    end

    pt.each do |proc_id, body|
      body['Versioned'].each do |version, versioned_info|
        begin
          ts = LangProc.where(proc_id: proc_id, version: version)
          lang_proc = ts.first
          raise "" if lang_proc.nil?

          lang_proc.description = body['Description']
          lang_proc.versioned_info = versioned_info
          lang_proc.save!

          tmp.delete(lang_proc.id)

        rescue Mongoid::Errors::DocumentNotFound, RuntimeError
          lang_proc = LangProc.new({
                                     :proc_id => proc_id,
                                     :description => body['Description'],
                                     :version => version,
                                     :versioned_info => versioned_info
                                   })
          lang_proc.save!

        end # begin
      end # body['Versioned'].each
    end # pt.each

    tmp.each_key do |key|
      LangProc.find(key).delete
    end
  end
  module_function :store_proc_table_to_db

  #
  def load_proc_table_from_db()
    h = ProcTableHolder.instance

    table = {}
    langprocs = LangProc.where({ :masked => false })
    langprocs.each do |langproc|
      unless table.has_key?(langproc.proc_id)
        table[langproc.proc_id] = {
          "Description" => langproc.description,
          "Versioned" => {}
        }
      end
      table[langproc.proc_id]["Versioned"][langproc.version] = langproc.versioned_info
    end

    h.set table
  end
  module_function :load_proc_table_from_db

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

    def cached?
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
