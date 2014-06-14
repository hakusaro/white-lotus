get '/admin/invite/create/:invite' do
  redirect to('/') unless params[:invite]
  Invite.create_invite(session[:admin_id], params[:invite])
end