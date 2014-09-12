class MasterController < ApplicationController
  before_filter :authenticate_user!
  before_filter :pass_only_manager!
  rescue_from CanCan::AccessDenied do |exception|
    redirect_to main_app.root_url, :alert => exception.message
  end
  def pass_only_manager!
    user = current_user
    authorize!(:manage, user)
  end

  # ==================================================
  #
  def index
    @procs = LangProc.all
  end

  # ==================================================
  #
  def update_proctable
    begin
      Cages.update_proc_table
      flash[:notice] = "ProcTable was successfully updated!"

    rescue => e
      flash[:error] = "Failed to update ProcTable"
    end

    redirect_to(:back)
  end

  #
  def enable_langproc
    change_langproc(params[:proc_id]) do |proc|
      proc.masked = false
    end
  end

  #
  def disable_langproc
    change_langproc(params[:proc_id]) do |proc|
      proc.masked = true
    end
  end

  # ==================================================
  #
  def list_users
    @users = User.order_by('created_at DESC').page(params[:page]).per(2)
  end

  #
  def delete_user
    user = User.find(params[:user_id])
    user.delete

    flash[:notice] = "#{user.name} / #{user.email} is deleted."

  rescue => e
    flash[:error] = "Failed to delete the user. #{e}"

  ensure
    redirect_to(:back)
  end

  #
  def update_node_addresses
    # TODO: implement
=begin
    nodes = []
    params["runner_num"].to_i.times do |i|
      nodes << { address: params["address_#{i}"], port: params["port_#{i}"] }
    end

    res = BackendServerBridge.update_runner_node_addresses( nodes )

    flash[res ? :notice : :error] = "update_node_addresses => #{res}"
=end
    redirect_to(:back)
  end

  private
  def change_langproc(id, &block)
    proc = LangProc.find(id)
    unless proc.nil?
      block.call(proc)
      proc.save!

      Cages.load_proc_table_from_db()
    else
      flash[:error] = "Specified langproc was not found"
    end

    redirect_to(:back)
  end
end
