before '/*' do
  if (session?) then
    @header = partial(:header, :locals => { login_state: true })
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

if (settings.environment == :development) then
  require_relative 'debug'
end