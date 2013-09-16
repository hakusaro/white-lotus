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
  response = RestClient.get("http://#{server.rest_api_ip}:#{server.rest_api_port}/v2/users/create?token=#{server.rest_token}&user=#{params['username']}&group=default&password=#{params['password']}")
  response2 = RestClient.get("http://#{server.rest_api_ip}:#{server.rest_api_port}/steam/user/add?token=#{server.rest_token}&username=#{params['username']}&steamid=#{session[:steam64]}")
  "Success."
end