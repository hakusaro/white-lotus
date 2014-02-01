get '/pry/?' do
  binding.pry
end

get '/delete/admins' do
	DB[:admins].delete
end