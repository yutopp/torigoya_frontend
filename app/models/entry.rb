class Entry
  include Mongoid::Document
  include Mongoid::Timestamps

  field :owner_user_id, :type => String, :default => nil
  field :revision, :type => String, :default => ""
  field :visibility, :type => Integer
  has_many :codes
  has_many :tickets

  field :tags, :type => Array, :default => []
  field :language_tags, :type => Array, :default => []
  field :viewed_count, :type => Integer, :default => 0
end


class Code
  include Mongoid::Document
  belongs_to :entry, :inverse_of => :codes

  field :file_id
  field :file_name, :type => String
  field :type, :type => Symbol  # :native, :gist
end


class Ticket
  include Mongoid::Document
  belongs_to :entry, :inverse_of => :tickets

  field :index, :type => Integer

  field :is_running, :type => Boolean
  field :processed, :type => Boolean

  field :do_execute, :type => Boolean
  field :proc_id, :type => Integer
  field :proc_version, :type => String
  field :proc_label, :type => String

  field :phase, :type => Integer

  embeds_one :compile_state
  embeds_one :link_state
  embeds_many :run_states
end


class State
  include Mongoid::Document

  field :index, :type => Integer

  field :used_cpu_time_sec, :type => Float
  field :used_memory_bytes, :type => Integer
  field :signal, :type => Integer
  field :return_code, :type => Integer
  field :command_line, :type => String
  field :status, :type => Integer
  field :system_error_message, :type => String

  field :structured_command_line, :type => Hash

  field :out, :type => Array
  field :err, :type => Array
end

class CompileState < State
  embedded_in :ticket, :inverse_of => :compile_state
end

class LinkState < State
  embedded_in :ticket, :inverse_of => :link_state
end

class RunState < State
  embedded_in :ticket, :inverse_of => :run_states
end
