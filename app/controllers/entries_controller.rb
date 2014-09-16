class EntriesController < ApplicationController
  #
  def show_list
    filtered_entry = if params[:query].nil? then
                       Entry.all
                     else
                       # do NOT distinguish Upper/Lower camel
                       Entry.in( language_tags: /#{Regexp.escape(params[:query])}/i )
                     end

    permission_filtered_entry = if user_signed_in? then
                                  if can? :manage, :all
                                    filtered_entry
                                  else
                                    # public OR own entry
                                    filtered_entry.any_of( { owner_user_id: current_user.id },
                                                           { visibility: 0 } )   # visibility means PUBLIC
                                  end
                                else
                                  # public
                                  filtered_entry.where( visibility: 0 )   # visibility means PUBLIC
                                end

    #
    @entries_only = permission_filtered_entry.desc( :id ).page( params[:page] ).per( 16 )

    @entries = @entries_only.map do |e|
      next {
        entry: e,
        user: User.where( id: e.owner_user_id ).first
      }
    end
  end

  class HasNoPermission
  end
  class NotSupported
  end

  ########################################
  #
  def show_entry
    @entry_id = params[:entry_id].to_s
    if @entry_id == "!search"
      return redirect_to :action => "show_list", :query => params[:query]
    end

    @entry = Entry.find(@entry_id)

    # check visibility
    if @entry["visibility"] == 2    # PRIVATE
      if user_signed_in? then
        if can? :manage, :all
          # pass
        else
          raise HasNoPermission.new unless @entry['owner_user_id'].to_s == current_user.id.to_s
        end
      else
        raise HasNoPermission.new
      end
    end

    codes = @entry.codes
    @filenames = codes.map do |c|
      c.file_name
    end

    grid_fs = Mongoid::GridFs
    @source_codes = codes.map do |c|
      case c.type
      when :native
        g = grid_fs.get(c.file_id)
        g.data

      else
        raise NotSupported.new
      end
    end

  rescue Mongoid::Errors::DocumentNotFound
    render :action => "not_found", :status => 404

  rescue HasNoPermission
    render :action => "not_permitted", :status => 403

  end


  ########################################
  #
  def not_found
  end


  ########################################
  #
  def not_permitted
  end
end
