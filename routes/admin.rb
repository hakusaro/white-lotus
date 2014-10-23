require 'digest'

get '/admin/invite/create/:invite' do
  redirect to('/') unless params[:invite]
  invite = Invite.create_invite(session[:admin_id], params[:invite])
  "Created new key " + invite.code + ". " + DB[:invites].all.to_s + " invites available."
end

get '/admin/invite/create' do
  md5 = Digest::MD5.new
  md5.update(rand(1234567).to_s)
  invite_code = md5.hexdigest
  invite = Invite.create_invite(session[:admin_id], invite_code)
  "Created new key " + invite.code + ". " + DB[:invites].all.to_s + " invites available."
end

get '/admin/servers' do
  output = @header
  servers = DB[:servers].all
  output << partial(:server_list, :locals => {
        server_list: servers
  })
  output << partial(:footer)
end

get '/admin/account/create/:steamid' do
  redirect to('/') unless params[:steamid]
  Admin.create_admin(params[:steamid])
  "added admin account"
end
