class Server < Sequel::Model
  def self.create_server(steam64,
    server_human_code,
    server_name,
    server_img_url,
    server_welcome,
    rest_api_ip,
    rest_api_port,
    rest_token,
    default_group,
    active,
    allow_multiple_accounts,
    allow_registration)
    Server.create(:steam64 => steam64,
      :server_human_code => server_human_code,
      :server_name => server_name,
      :server_img_url => server_img_url,
      :server_welcome => server_welcome,
      :rest_api_port => rest_api_port,
      :rest_api_ip => rest_api_ip,
      :rest_token => rest_token,
      :active => active,
      :default_group => default_group,
      :allow_multiple_accounts => allow_multiple_accounts,
      :allow_registration => allow_registration,
      :created => Time.now.to_i.to_s)
  end
end

Server.set_dataset :servers
