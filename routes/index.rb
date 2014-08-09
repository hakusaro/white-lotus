get '/' do
  output = @header
  output << partial(:index, :locals => {login_state: session?})
  output << partial(:footer)
  output
end
