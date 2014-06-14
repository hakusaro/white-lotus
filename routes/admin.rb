get '/admin/invite/create/:invite' do
  redirect to('/') unless params[:invite]
  invite = Invite.create_invite(session[:admin_id], params[:invite])
  "Created new key " + invite.code + ". " + DB[:invites].all.to_s + " invites available."
end