class FilesystemController < ApplicationController    
  require 'net/ssh'
  require 'net/sftp'
  # before_filter :authenticate_user!

  def login
    cookie_data = {:password => params['password']}
    digest = 'SHA1'
    secret = ENV('COOKIEKEY')
    data = ActiveSupport::Base64.encode64s(Marshal.dump(cookie_data))
    digest_value = OpenSSL::HMAC.hexdigest(OpenSSL::Digest::Digest.new(digest), secret, data)
    escaped_data_value = Rack::Utils.escape(data)
    final_output = "#{escaped_data_value}--#{digest_value}"
    cookies[:details] = final_output
    @thing = { login: 'good' }
    render json: @thing
  end

  def peek
    folder = '~'
    if params['folder']
      folder = params['folder']
    end
    @contents = {}
    @contents['folders'] = []
    @contents['files'] = []
    sftp = nil
    if current_user #THIS IS A BACKDOOR
      sftp = check_sftp_connection(current_user,current_user.servers.where(id: params['server'].to_i))
    else
      obj = BackdoorObject.new
      sftp = check_sftp_connection(obj,obj)
    end
    sftp.dir.foreach(folder) do |entry|
      temp = {}
      temp['name'] = entry.name
      temp['path'] = folder+"/"+entry.name
      if entry.directory?
        @contents['folders'] << temp
      else
        @contents['files'] << temp
      end
    end
    render json: @contents
  end

  def open

  end

  def save

  end

  private
  def get_login
    Marshal.load(ActiveSupport::Base64.decode64(cookies[:details]))
  end

  def check_sftp_connection(user, server)
    Thread.current[:user_connections] ||= {}
    unless Thread.current[:user_connections][user.id][server.id]
      Net::SSH.start(host, username, :password => password, :port => port)
      Thread.current[:user_connections][user.id][server.id] = Net::SFTP::Session.new(session).connect!
    end
    Thread.current[:user_connections][user.id][server.id]
  end

  class BackdoorObject << self
    @id = 1234
  end
end
