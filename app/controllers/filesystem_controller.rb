class FilesystemController < ApplicationController    
  require 'net/ssh'
  require 'net/sftp'
  # require 'activesupport'
  skip_before_filter  :verify_authenticity_token
  # before_filter :authenticate_user!

  def login
    binding.pry
    if params['password'].nil? || current_user.servers.find(params[:id].to_i).nil?
      @thing = { login: 'bad' }
      render json: @thing
      return
    end
    binding.pry
    current_server = current_user.servers.find(params[:id].to_i)
    cookie_data = {:password => params['password']}
    cookies[:hostname] = current_server.hostname
    cookies[:username] = current_server.username
    digest = 'SHA1'
    secret = 'cookiekey'
    data = Base64.encode64(Marshal.dump(cookie_data))
    digest_value = OpenSSL::HMAC.hexdigest(OpenSSL::Digest::Digest.new(digest), secret, data)
    escaped_data_value = Rack::Utils.escape(data)
    final_output = "#{escaped_data_value}--#{digest_value}"
    cookies.encrypted[:details] = final_output
    check_sftp_connection(current_user, current_user.servers.find(params[:id].to_i))
    @thing = { login: 'good' }
    render json: @thing
  rescue
    @thing = { login: 'bad' }
    render json: @thing
    return
  end

  def peek
    folder = '.'
    if params['id'] && params['id'] != '1'
      folder = params['id']
    end
    @contents = []
    sftp = nil
    if current_user #THIS IS A BACKDOOR
      sftp = get_sftp_connection(current_user)
    else
      obj = BackdoorObject.new
      sftp = check_sftp_connection(obj,obj)
    end
    if sftp.nil?
      logger.error "failed at a thing"
      @thing = { login: 'bad' }
      render json: @thing
      return
    end
    sftp.dir.foreach(folder) do |entry|
      temp = {}
      temp['name'] = entry.name
      temp['path'] = folder+"/"+entry.name
      if entry.name[0] != '.'
        if entry.directory?
          @contents << build_folder(temp["name"],temp["path"])
        else
          @contents << build_file(temp["name"],temp["path"])
        end
      end
    end
    render json: @contents
  end

  def open
    sftp = nil
    if current_user  #THIS IS A BACKDOOR
      sftp = get_sftp_connection(current_user)
    else
      obj = BackdoorObject.new
      sftp = check_sftp_connection(obj,obj)
    end
    if sftp.nil?
      @thing = { login: 'bad' }
      render json: @thing
      return
    end
    @data = {}
    @data["contents"] = sftp.download!(params['file'])
    @data["path"] = params['file']
    render text: @data['contents']
  end

  def save
    sftp = nil
    if current_user  #THIS IS A BACKDOOR
      sftp = get_sftp_connection(current_user)
    else
      obj = BackdoorObject.new
      sftp = check_sftp_connection(obj,obj)
    end
    if sftp.nil?
      @thing = { login: 'bad' }
      render json: @thing
      return
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

  def has_password
    if cookies.encrypted[:details].nil? || get_login()[:password].nil?
      return false
    end
    return true
  end

  def check_sftp_connection(user, server)
    Thread.current[:user_connections] ||= {}
    if !has_password
      return nil
    end
    if server.port.nil?
      port = 22
    else
      port = server.port
    end
    unless Thread.current[:user_connections][user.id]
      session = Net::SSH.start(server.hostname, server.username, :password => get_login()[:password], :port => port, :auth_methods => [ 'password' ],:number_of_password_prompts => 0)
      Thread.current[:user_connections][user.id] = Net::SFTP::Session.new(session).connect!
    end
    Thread.current[:user_connections][user.id]
  end

  def get_sftp_connection(user)
    Thread.current[:user_connections] ||= {}
    if !has_password
      return nil
    end
    if get_login()[:password].nil?
      return nil
    end
    unless Thread.current[:user_connections][user.id]
      session = Net::SSH.start(cookies[:hostname], cookies[:username], :password => get_login()[:password], :port => 22, :auth_methods => [ 'password' ],:number_of_password_prompts => 0)
      Thread.current[:user_connections][user.id] = Net::SFTP::Session.new(session).connect!
    end
    Thread.current[:user_connections][user.id]
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

  def build_folder(name, path)
    file = {}
    file[:id] = path
    file[:text] = name
    file[:icon] = 'jstree-custom-folder'
    file[:state] = {opened: false, disabled: false, selected:false}
    file[:li_attr] = {base: path, isLeaf: false}
    file[:children] = true
    return file
  end

  def build_file(name, path)
    file = {}
    file[:id] = path
    file[:text] = name
    file[:icon] = 'jstree-custom-file'
    file[:state] = {opened: false, disabled: false, selected:false}
    file[:li_attr] = {base: path, isLeaf: true}
    file[:children] = false
    return file
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
