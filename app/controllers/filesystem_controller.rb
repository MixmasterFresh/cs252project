class FilesystemController < ApplicationController    
  require 'net/ssh'
  require 'net/sftp'
  # require 'activesupport'
  skip_before_filter  :verify_authenticity_token
  # before_filter :authenticate_user!

  def login
    if params['password'].nil?
      @thing = { login: 'bad' }
      render json: @thing
      return
    end
    cookie_data = {:password => params['password']}
    digest = 'SHA1'
    secret = 'cookiekey'
    data = Base64.encode64(Marshal.dump(cookie_data))
    digest_value = OpenSSL::HMAC.hexdigest(OpenSSL::Digest::Digest.new(digest), secret, data)
    escaped_data_value = Rack::Utils.escape(data)
    final_output = "#{escaped_data_value}--#{digest_value}"
    cookies.encrypted[:details] = final_output
    @thing = { login: 'good' }
    render json: @thing
  end

  def peek
    folder = '.'
    if params['folder']
      folder = params['folder']
    end
    @contents = {}
    @contents['folders'] = []
    @contents['files'] = []
    sftp = nil
    if current_user && params[:id].to_i != 1234 #THIS IS A BACKDOOR
      sftp = check_sftp_connection(current_user,current_user.servers.find(params[:id].to_i))
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
    sftp = nil
    if current_user && params[:id].to_i != 1234  #THIS IS A BACKDOOR
      sftp = check_sftp_connection(current_user,current_user.servers.find(id: params[:id].to_i))
    else
      obj = BackdoorObject.new
      sftp = check_sftp_connection(obj,obj)
    end
    @data = {}
    @data["contents"] = sftp.download!(params['file'])
    @data["path"] = params['file']
    render json: @data
  end

  def save
    sftp = nil
    if current_user && params[:id].to_i != 1234  #THIS IS A BACKDOOR
      sftp = check_sftp_connection(current_user,current_user.servers.find(id: params[:id].to_i))
    else
      obj = BackdoorObject.new
      sftp = check_sftp_connection(obj,obj)
    end
    sftp.file.open(params['path'], "w") do |f|
      f.print params['contents'].undump
    end
  end

  private
  def get_login
    if cookies.encrypted[:details]
      Marshal.load(Base64.decode64(cookies.encrypted[:details]))
    else
      ""
    end
  end

  def check_sftp_connection(user, server)
    Thread.current[:user_connections] ||= {}
    Thread.current[:user_connections][user.id] ||= {}
    if server.port.nil?
      port = 22
    else
      port = server.port
    end
    unless Thread.current[:user_connections][user.id][server.id]
      session = Net::SSH.start(server.hostname, server.username, :password => get_login()[:password], :port => port, :auth_methods => [ 'password' ],:number_of_password_prompts => 0)
      Thread.current[:user_connections][user.id][server.id] = Net::SFTP::Session.new(session).connect!
    end
    Thread.current[:user_connections][user.id][server.id]
  end

  class BackdoorObject
    def id 
      1234
    end
    def hostname
      "frodo.rcac.purdue.edu"
    end
    def username
      "ahornin"
    end
    def port
      nil
    end
  end

  String.class_eval do
    def undump
      self.sub(/\A"/, '').sub(/"\z/, '').gsub(/\\(x([0-9a-f]{2})) | \\(u\{([0-9a-f]{4})\}) | \\(.) /ix)  {
        if $1 # \xXX
          [$2.hex].pack("C")
        elsif $3 # \u{xxxx}
          [$4.hex].pack("U")
        else # \.
          case $5
          when 't'
            "\t"
          when 'v'
            "\v"
          when 'n'
            "\n"
          when 'r'
            "\r"
          when 'f'
            "\f"
          when 'b'
            "\b"
          when 'a'
            "\a"
          when 'e'
            "\e"
          when 's'
            " "
          else
            $5
          end
        end
      }
    end
  end
end
