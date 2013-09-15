class AddRestToken < Sequel::Migration
  def up
    add_column :servers, :rest_token, String
  end
  def down
    drop_column :servers, :rest_token
  end
end