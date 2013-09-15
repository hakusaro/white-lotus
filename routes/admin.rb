get '/admin/invite/create/:invite' do
  redirect to('/') unless params[:invite]
  Invite.create(:admin_id => session[:admin_id], :code => params[:invite])
end