get '/' do
  output = @header
  output << partial(:generic, :locals => {
    title: 'Test',
    heading: 'Partially cool.',
    body: 'This is a test of the partial engine.'
    })
  output << partial(:footer)
  output
end