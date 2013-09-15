class AddInviteTable < Sequel::Migration
  def up
    create_table(:invites) do
      primary_key :id
      foreign_key :admin_id, :admins
      String :code
    end
  end
  def down
    drop_table(:invites)
  end
end