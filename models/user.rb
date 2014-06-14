class User < Sequel::Model
  def self.create_user(
    serverid,
    account_name,
    steam64
  )
    User.create(
        :server_id => serverid,
        :account_name => account_name,
        :steam64 => steam64,
        :banned => false,
        :created => Time.now.to_i.to_s
    )
  end
end

User.set_dataset :users