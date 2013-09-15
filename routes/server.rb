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
    begin
      Server.create_server(session[:steam64],
        params["server_key"],
        params["server_name"],
        params["server_img_url"],
        params["server_welcome"],
        params["rest_api_port"],
        params["rest_api_ip"],
        params["rest_api_token"],
        true,
        false,
        true)
      DB[:invites].where(:code => params["invite_code"]).delete
    rescue
      puts "Unexpected error during creation!!!"
      "Fail!"
    end
    "Success."
  else
    "No invitation code!"
  end
end