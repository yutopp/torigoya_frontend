class HomeController < ApplicationController
  def index
    @cloned_from_entry_id = params[:entry_id]
  end
end
