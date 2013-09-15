# Hey there, this runs a database migration.
# From a command line, execute:
# > sequel -m . -M 1 mysql://user:pass@host/database_name
# 
# Example:
# > sequel -m . -M 1 mysql://root@localhost/white_lotus

Sequel.migration do
  up do
    create_table(:servers) do
      primary_key :id
      String :steam64
      String :server_human_code
      String :server_name
      String :server_img_url
      String :server_description
      String :rest_api_ip
      Time :created
      Integer :rest_api_port
      Boolean :active
      Boolean :allow_registration
      Boolean :allow_multiple_accounts
    end

    create_table(:users) do
      primary_key :id
      foreign_key :server_id, :servers
      String :account_name
      String :steam64
      Boolean :banned
      Time :created 
    end

    create_table(:admins) do
      primary_key :id
      String :steam64
    end
  end
  down do
    drop_table(:users)
    drop_table(:admins)
    drop_table(:servers)
  end
end