get '/create/server/?' do
  redirect to('/login/stage/1/') unless session? && session[:logged_in]
  output = @header
  output << partial(:create_server)
  output << partial(:footer)
  output
end

post '/create/server/?' do
  redirect to('/login/stage/1/') unless session? && session[:logged_in]
  required_params = [
    "server_name",
    "server_key",
    "rest_api_ip",
    "rest_api_port",
    "rest_api_token",
    "default_group",
    "invite_code"]

  optional_params = [
    "server_welcome",
    "server_img_url"]

  required_params.each do |param|
    if (!params[param]) then
      raise "Parameter #{param} is missing on post request!"
    else
      begin
        params[param].strip!.chomp!
      rescue NoMethodError, TypeError
        # There are a couple values that aren't going to be strings...
      end 
    end
  end

  optional_params.each do |param|
    if (params[param]) then
      begin
        params[param].strip!.chomp!
      rescue NoMethodError, TypeError
        # More empty values
      end
    end
  end

  invites = DB[:invites].where(:code => params["invite_code"]).all
  if (invites.count > 0) then
    used_key = DB[:servers].where(:server_human_code => params["server_key"]).all
    if(used_key.count > 0)
      "Server key is already used."
    else
      begin
        Server.create_server(session[:steam64],
          params["server_key"],
          params["server_name"],
          params["server_img_url"],
          params["server_welcome"],
          params["rest_api_ip"],
          params["rest_api_port"],
          params["rest_api_token"],
          params["default_group"],
          true,
          true,
          true)
        DB[:invites].where(:code => params["invite_code"]).delete
      rescue
        puts "Unexpected error during creation!!!"
        "Fail!"
      end
      redirect to('/servers')
    end
  else
    "No invitation code!"
  end
end

get '/servers' do
  redirect to('/login/stage/1/') unless session? && session[:logged_in]

  output = @header
  servers = DB[:servers].where(:steam64 => session[:steam64]).all
  if servers.count == 0
    redirect to('/create/server')
  else
    output << partial(:server_list, :locals => {
        server_list: servers
    })
  end
  output << partial(:footer)
end

get '/modify/server/:serverid' do
  redirect to('/login/stage/1/') unless session? && session[:logged_in]
  output = @header

  server = Server[:id => params[:serverid]]

  if server == nil
    output << "Invalid server."
  else
    if server.steam64 != session[:steam64]
      output << "You do not own this server :("
    else
      session[:modify_server] = server.id
      output << partial(:edit_server, :locals => {
          server: server
      })
    end
  end
  output << partial(:footer)
end

get '/modify/server/' do
  redirect to('/servers')
end

post '/modify/server/?' do
  redirect to('/login/stage/1/') unless session? && session[:logged_in]
  required_params = [
      "server_name",
      "rest_api_ip",
      "rest_api_port",
      "default_group",
      "rest_token"]

  optional_params = [
      "server_welcome",
      "server_img_url"]

  required_params.each do |param|
    if (!params[param]) then
      raise "Parameter #{param} is missing on post request!"
    else
      begin
        params[param].strip!.chomp!
      rescue NoMethodError, TypeError
        # There are a couple values that aren't going to be strings...
      end
    end
  end

  optional_params.each do |param|
    if (params[param]) then
      begin
        params[param].strip!.chomp!
      rescue NoMethodError, TypeError
        # More empty values
      end
    end
  end

  if session[:modify_server] == nil
    redirect to('/servers')
  end

  server = Server[:id => session[:modify_server]]
  if server == nil
    redirect to('/servers')
  end

  DB[:servers].where(:id => server.id).update(
      :server_name => params["server_name"],
      :server_welcome => params["server_welcome"],
      :rest_api_ip => params["rest_api_ip"],
      :rest_api_port => params["rest_api_port"],
      :rest_token => params["rest_token"],
      :server_img_url => params["server_img_url"],
      :default_group => params["default_group"]
  )
  session[:modify_server] = nil
  redirect to('/servers')
end

get '/view/server/:serverid' do
  redirect to('/login/stage/1/') unless session? && session[:logged_in]
  output = @header

  server = Server[:id => params[:serverid]]

  if server == nil
    output << "Invalid server."
  else
    if server.steam64 != session[:steam64]
      output << "You do not own this server :("
    else
      users = DB[:users].where(:server_id => server.id).all
      output << partial(:server_info, :locals=> {
          server: server,
          user_list: users
      })
    end
  end
  output << partial(:footer)
end
