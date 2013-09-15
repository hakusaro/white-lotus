before '/*' do
  if (session?) then
    @header = partial(:header, :locals => { login_state: true })
  else
    @header = partial(:header, :locals => { login_state: false })
  end
end

require_relative 'index'
require_relative 'authentication'

if (settings.environment == :development) then
  require_relative 'debug'
end