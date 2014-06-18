Sequel.migration do
  up do
    add_column :servers, :default_group, String
  end
  down do
    drop_column :servers, :default_group
  end
end
