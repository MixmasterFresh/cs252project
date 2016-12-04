class ServersController < ApplicationController
  def new
    @server = Server.new
  end

  def create
    @server = Server.new(server_params)
    @server.user = current_user
    @server.save!
    redirect_to servers_path
  end

  def destroy
    Server.find(params[:id].to_i).delete
    redirect_to servers_path
  end


private
  def server_params
    params.require(:server).permit(:name, :username, :hostname)
  end
end
