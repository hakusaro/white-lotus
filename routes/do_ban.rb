get '/ban/?' do
  required_params = [
      "username",
      "serverkey"
  ]

  required_params.each do |param|
    if (!params[param]) then
      400
    end
  end

  users = DB[:users].where(Sequel.and(:server_id => params['serverkey'], :account_name => params['username'])).all
  if(users.count > 0)
    DB[:users].where(Sequel.and(:server_id => params['serverkey'], :account_name => params['username'])).delete
  end
end