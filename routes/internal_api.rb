get '/ban/create/:steam/:serverkey' do
  redirect to('/login/stage/1/') unless session? && session[:logged_in]
  
  output = @header
  
  server = Server[:id => params[:serverkey]]
  if server == nil
    output << partial(:generic_message, :locals =>
    {
      topic: "Invalid Server ID",
      message: "You specified the Server ID of an invalid server.",
      redirect: true,
      redirect_url: "/servers",
      redirect_message: "Return to the server list."
    })
  end

  if server.steam64 != session[:steam64]
    output << partial(:generic_message, :locals =>
    {
      topic: "Invalid Server ID",
      message: "You are not the owner of that server.",
      redirect: true,
      redirect_url: "/view/server/" + params[:serverkey],
      redirect_message: "Return to your server."
    })
  end

  users = DB[:users].where(:server_id => params[:serverkey], :steam64 => params[:steam], :banned => false).all
  if(users.count > 0)
    count = DB[:users].where(:server_id => params[:serverkey], :steam64 => params[:steam]).update(:banned=>true)
    output << partial(:generic_message, :locals =>
    {
      topic: "Successfully banned " + params[:steam] + ".",
      message: "You banned " + count.to_s + " accounts.",
      redirect: true,
      redirect_url: "/view/server/" + params[:serverkey],
      redirect_message: "Return to your server."
    })
  else
    output << partial(:generic_message, :locals =>
    {
      topic: "Invalid User",
      message: "We could not find any users on your server with that Steam ID.",
      redirect: true,
      redirect_url: "/view/server/" + params[:serverkey],
      redirect_message: "Return to your server."
    })
  end
  
  #TODO send api call to tshock plugin.
  
  output << partial(:footer)
end

get '/ban/delete/:steam/:serverkey' do
  redirect to('/login/stage/1/') unless session? && session[:logged_in]
  
  output = @header
  
  server = Server[:id => params[:serverkey]]
  if server == nil
    output << partial(:generic_message, :locals =>
    {
      topic: "Invalid Server ID",
      message: "You specified the Server ID of an invalid server.",
      redirect: true,
      redirect_url: "/servers",
      redirect_message: "Return to the server list."
    })
  end

  if server.steam64 != session[:steam64]
    output << partial(:generic_message, :locals =>
    {
      topic: "Invalid Server ID",
      message: "You are not the owner of that server.",
      redirect: true,
      redirect_url: "/view/server/" + params[:serverkey],
      redirect_message: "Return to your server."
    })
  end

  users = DB[:users].where(:server_id => params[:serverkey], :steam64 => params[:steam], :banned => true).all
  if(users.count > 0)
    count = DB[:users].where(:server_id => params[:serverkey], :steam64 => params[:steam]).update(:banned=>false)
    output << partial(:generic_message, :locals =>
    {
      topic: "Successfully unbanned " + params[:steam] + ".",
      message: "You unbanned " + count.to_s + " accounts.",
      redirect: true,
      redirect_url: "/view/server/" + params[:serverkey],
      redirect_message: "Return to your server."
    })
  else
    output << partial(:generic_message, :locals =>
    {
      topic: "Invalid User",
      message: "We could not find any users on your server with that Steam ID.",
      redirect: true,
      redirect_url: "/view/server/" + params[:serverkey],
      redirect_message: "Return to your server."
    })
  end
  
  #TODO send api call to tshock plugin.
  
  output << partial(:footer)
end

get '/user/delete/:name/:serverkey?' do
  redirect to ('/login/stage/1') unless session? && session[:logged_in]
  output = @header

  server = Server[:id => params[:serverkey]]
  if server == nil
    output << partial(:generic_message, :locals =>
        {
            topic: "Invalid Server ID",
            message: "You specified the Server ID of an invalid server.",
            redirect: true,
            redirect_url: "/servers",
            redirect_message: "Return to the server list."
        })
  end

  if server.steam64 != session[:steam64]
    output << partial(:generic_message, :locals =>
        {
            topic: "Invalid Server ID",
            message: "You are not the owner of that server.",
            redirect: true,
            redirect_url: "/view/server/" + params[:serverkey],
            redirect_message: "Return to your server."
        })
  end

  users = DB[:users].where(:server_id => params[:serverkey], :account_name => params[:name]).all
  if(users.count > 0)
    response = RestClient.get("http://#{server.rest_api_ip}:#{server.rest_api_port}/v2/users/create?token=#{server.rest_token}&user=#{params['username']}&group=#{server.default_group}&password=#{params['password']}")
    resp = JSON.parse(response.to_s)
    if resp['status'] == "200"
      count = users.delete()
      output << partial(:generic_message, :locals =>
          {
              topic: "Successfully deleted " + params[:name] + ".",
              message: "You deleted " + count.to_s + " accounts.",
              redirect: true,
              redirect_url: "/view/server/" + params[:serverkey],
              redirect_message: "Return to your server."
          })
    else
      output << partial(:generic_message, :locals =>
          {
              topic: "TShock Failure",
              message: "We failed to delete the user from TShock",
              redirect: true,
              redirect_url: "/view/server/" + params[:serverkey],
              redirect_message: "Return to your server."
          })
    end

  else
    output << partial(:generic_message, :locals =>
        {
            topic: "Invalid User",
            message: "We could not find any users on your server with that name.",
            redirect: true,
            redirect_url: "/view/server/" + params[:serverkey],
            redirect_message: "Return to your server."
        })
  end

  output << partial(:footer)
end