Sequel.migration do
  up do
    create_table(:invites) do
      primary_key :id
      foreign_key :admin_id, :admins
      String :code
    end
  end
  down do
    drop_table(:invites)
  end
end