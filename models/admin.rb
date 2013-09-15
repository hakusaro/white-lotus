class Admin < Sequel::Model
  def self.create_admin(steam64)
    Admin.create(:steam64 => steam64)
  end
end

Admin.set_dataset :admins