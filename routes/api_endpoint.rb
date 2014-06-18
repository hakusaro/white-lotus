get '/ban/create/:steam/:serverkey/:token' do
  server = Server[:id => params[:serverkey]]
  if server == nil
    return [500, "Server does not exist"]
  end

  if server.rest_token != params[:token]
    return [500, "Server does not exist"]
  end

  users = DB[:users].where(:server_id => params[:serverkey], :steam64 => params[:steam], :banned => false).all
  if(users.count > 0)
    count = DB[:users].where(:server_id => params[:serverkey], :steam64 => params[:steam]).update(:banned=>true)
    return [200, "Banned " + count.to_s + " accounts on that server."]
  else
    return [500, "Failed to find any users with that name on that server."]
  end
end

get '/ban/delete/:steam/:serverkey/:token' do
  server = Server[:id => params[:serverkey]]
  if server == nil
    return [500, "Server does not exist"]
  end

  if server.rest_token != params[:token]
    return [500, "Invalid token"]
  end

  users = DB[:users].where(:server_id => params[:serverkey], :steam64 => params[:steam], :banned => true).all
  if(users.count > 0)
    count = DB[:users].where(:server_id => params[:serverkey], :steam64 => params[:steam]).update(:banned=>false)
    return [200, "Unbanned " + count.to_s + " accounts on that server."]
  else
    return [500, "Failed to find any users with that name on that server."]
  end
end

get '/user/lookup/:steamid/:serverkey/:token' do
  server = Server[:id => params[:serverkey]]
  if server == nil
    return [500, "Server does not exist"]
  end

  if server.rest_token != params[:token]
    return [500, "Invalid token"]
  end

  users = DB[:users].where(:steam64 => params[:steamid], :banned => true).all
  count = users.uniq{|u| u[:server_id]}
  resp = "{\"GlobalBans\": " + count.count.to_s + "}"
  print resp
  return [200, resp]
end
