Sequel.migration do
  up do
    add_column :servers, :rest_token, String
  end
  down do
    drop_column :servers, :rest_token
  end
end