post '/auth/steam/callback/?' do
  hash = request.env['omniauth.auth']
  hash.uid.slice!('http://steamcommunity.com/openid/id/')
  session[:steam64] = hash.uid
  redirect to('/login/stage/2/')
end

get '/login/stage/2/?' do

end

get '/login/stage/1/?' do
  if (session?) then
    session_end!(true)
  end

  session_start!
  session[:logged_in] = false
  redirect to('/auth/steam/')
end

get '/logout/?' do
  session_end!(true)
  redirect to('/')
end