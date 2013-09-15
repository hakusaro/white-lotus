get '/' do
  output = @header
  output << partial(:index)
  output << partial(:footer)
  output
end