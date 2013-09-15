get '/create/server/?' do
  redirect to('/login/stage/1/') unless session? && session[:logged_in]
  output = @header
  output << partial(:create_server)
  output << partial(:footer)
  output
end

post '/create/server/?' do
  redirect to('/login/stage/1/') unless session? && session[:logged_in]
end