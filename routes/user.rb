require 'json'

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
    puts "making first request"
    response = RestClient.get("http://#{server.rest_api_ip}:#{server.rest_api_port}/v2/users/create?token=#{server.rest_token}&user=#{params['username']}&group=#{server.default_group}&password=#{params['password']}")
    puts "completed first request"
    resp = JSON.parse(response.to_s)
    if resp['status'] == "200"
      puts "making second request"
      response2 = RestClient.get("http://#{server.rest_api_ip}:#{server.rest_api_port}/steam/user/add?token=#{server.rest_token}&username=#{params['username']}&steamid=#{session[:steam64]}")
      puts "completed second request"
      resp = JSON.parse(response2.to_s)
      if resp['status'] == "200"
        User.create_user(session[:server_id], params['username'], session[:steam64])
        return [200, "Success"]
        "Success." # TODO: render the right page thing.
      else
        puts response2.to_s
        return [500, "Failed to create a Steam user at remote location"]
      end
    else
      puts response.to_s
      return [500, "Failed to create a TShock user at remote location"]
    end
  rescue Exception => e
    return [500, "Failure - Internal exception: " + e.to_s]
  end
end
