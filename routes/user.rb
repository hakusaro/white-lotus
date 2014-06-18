get '/create/user/?' do
  redirect to('/login/stage/1/') unless session? && session[:logged_in] && session[:server_id]
  server = Server[:id => session[:server_id]]
  output = @header
  output << partial(:create_user, :locals => {
    server_name: server.server_name,
    server_welcome: server.server_welcome,
    server_img_url: server.server_img_url
    })
  output << partial(:footer)
end

post '/create/user/?' do
  redirect to('/login/stage/1/') unless session? && session[:logged_in] && session[:server_id]
  required_params = [
    "username",
    "password"]

  required_params.each do |param|
    if (!params[param]) then
      redirect to('/create/user/')
    end
  end

  server = Server[:id => session[:server_id]]
  is_banned = DB[:users].where(:steam64 => session[:steam64], :server_id => server.id, :banned => true).all
  if is_banned.count > 0
    return "You are banned from this server."
  end

  existing_user = DB[:users].where(:steam64 => session[:steam64], :server_id => server.id).all
  if existing_user.count > 0 && server.allow_multiple_accounts
    return "You have already created an account on this server: " + existing_user[0][:account_name]
  end
  begin
    #response = RestClient.get("http://#{server.rest_api_ip}:#{server.rest_api_port}/v2/users/create?token=#{server.rest_token}&user=#{params['username']}&group=#{server.default_group}&password=#{params['password']}")
    #if response.code == "200"
    #  response2 = RestClient.get("http://#{server.rest_api_ip}:#{server.rest_api_port}/steam/user/add?token=#{server.rest_token}&username=#{params['username']}&steamid=#{session[:steam64]}")
    #  if response2.code == "200"
    User.create_user(session[:server_id], params['username'], session[:steam64])
    return [200, "Success"]
    ##    "Success." # TODO: render the right page thing.
    #  else
    #    return response2, 500
    #  end
    #else
    #  return response, 500
    #end
  rescue Exception => e
    return [500, "Failure - Internal exception: "]
  end
end
