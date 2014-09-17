class AboutController < ApplicationController
  def index
    versionfile_path = File.join(Rails.root, ".frontend_version")
    @version = if File.exists?(versionfile_path) then
                 File.open(File.join(Rails.root, ".frontend_version"), "r").read
               else
                 "(not versioned)"
               end
  end
end
