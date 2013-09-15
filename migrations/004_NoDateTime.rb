Sequel.migration do
  up do
    drop_column :servers, :created
    drop_column :users, :created
    add_column :users, :created, String
    add_column :servers, :created, String
    rename_column :servers, :server_description, :server_welcome
  end
  down do
    drop_column :servers, :created
    drop_column :users, :created
    add_column :users, :created, Time
    add_column :servers, :created, Time
    rename_column :servers, :server_welcome, :server_description
  end
end