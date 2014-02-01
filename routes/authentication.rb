get '/login/stage/1/?' do
  if (session?) then
    session_end!(true)
  end

  session_start!
  session[:logged_in] = false
  redirect to('/auth/steam/')
end

get '/login/stage/2/?' do
  redirect to('/login/stage/1/') unless session? && session[:logged_in]
  output = @header
  output << partial(:logon_select)
  output << partial(:footer)
  output
end

post '/login/stage/3/?' do
  redirect to('/login/stage/1/') unless session? && session[:logged_in]
  if (params['server_key']) then
    servers = DB[:servers].where(:server_human_code => params['server_key']).all
    servers.each do |server|
      session[:server_id] = server[:id]
    end
    redirect to('/login/stage/2/') unless session[:server_id]
  else
    redirect to('/login/stage/2/')
  end
  redirect to('/create/user/')
end

get '/login/stage/4/?' do
  redirect to('/login/stage/1/') unless session? && session[:logged_in]
  all_servers = DB[:servers]
  owned_servers = all_servers.where(:steam64 => session[:steam64]).all
  if (owned_servers.count == 0) then
    redirect to('/create/server/')
  else
    puts "YOLO" # Placeholder I guess thing.
  end
end

get '/login/admin/?' do
  redirect to('/login/stage/1/') unless session? && session[:logged_in]
  all_admins = DB[:admins]
  if (all_admins.all.count == 0) then
    Admin.create_admin(session[:steam64])
  end
  admins = all_admins.where(:steam64 => session[:steam64]).all
  if (admins.count == 0) then
    redirect to('/')
  else
    admins.each do |admin|
      session[:admin_id] = admin[:id]
      session[:is_admin] = true
    end
  end
  output = @header
  output << partial(:generic, :locals => {
    title: 'Success',
    heading: 'Admin login complete.',
    body: 'You are now logged in as an admin.'
    })
  output << partial(:footer)
  output
end

post '/auth/steam/callback/?' do
  hash = request.env['omniauth.auth']
  hash.uid.slice!('http://steamcommunity.com/openid/id/')
  session[:steam64] = hash.uid
  session[:logged_in] = true
  redirect to('/login/stage/2/')
end

get '/logout/?' do
  session_end!(true)
  redirect to('/')
end