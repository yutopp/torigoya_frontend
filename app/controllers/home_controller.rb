class HomeController < ApplicationController
  def index
    @cloned_from_entry_id = params[:entry_id]
    @source_codes = nil
    unless @cloned_from_entry_id.nil?
      @source_codes = Entry.find(@cloned_from_entry_id).codes.map{|c| c.source_code}
    end
  end
end
