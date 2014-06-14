get '/ban/create/:username/:serverkey' do
  users = DB[:users].where(:server_id => params[:serverkey], :account_name => params[:username], :banned => false).all
  if(users.count > 0)
    DB[:users].where(:server_id => params[:serverkey], :account_name => params[:username]).update(:banned=>true)
    "Banned " + users.count.to_s + " accounts on that server."
  else
    "Failed to find any users with that name on that server."
  end
end

get '/ban/delete/:username/:serverkey' do
  users = DB[:users].where(:server_id => params[:serverkey], :account_name => params[:username], :banned => true).all
  if(users.count > 0)
    DB[:users].where(:server_id => params[:serverkey], :account_name => params[:username]).update(:banned=>false)
    "Unbanned " + users.count.to_s + " accounts on that server."
  else
    "Failed to find any users with that name on that server."
  end
end