class LangProc
  include Mongoid::Document

  field :proc_id, :type => Integer
  field :description, :type => Hash

  field :version, :type => String
  field :versioned_info, :type => Hash

  field :masked, :type => Boolean, :default => false
end
