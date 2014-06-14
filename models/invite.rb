class Invite < Sequel::Model
  def self.create_invite(
    admin_id,
    code
  )
  Invite.create(
      :admin_id => admin_id,
      :code => code
  )
  end
end

Invite.set_dataset :invites