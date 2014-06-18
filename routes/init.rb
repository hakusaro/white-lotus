before /^(?!\/(ban))/ do
  if (session?) then
    @header = partial(:header, :locals => { login_state: true })
    if (settings.environment == :development) then
      puts "---SESSION DEBUG---"
      ap session
      puts "---SESSION DEBUG---"
    end
  else
    @header = partial(:header, :locals => { login_state: false })
  end
end

before '/admin/*' do
  redirect to('/login/stage/1/') unless session? && session[:logged_in] && session[:is_admin]
end

require_relative 'index'
require_relative 'authentication'
require_relative 'server'
require_relative 'admin'
require_relative 'user'
<<<<<<< Updated upstream
require_relative 'ban_endpoint'
require_relative 'steam'
=======
require_relative 'api_endpoint'
>>>>>>> Stashed changes

if (settings.environment == :development) then
  require_relative 'debug'
end
