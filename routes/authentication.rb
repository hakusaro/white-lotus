post '/auth/steam/callback?' do
  hash = request.env['omniauth.auth']
  ap hash
end