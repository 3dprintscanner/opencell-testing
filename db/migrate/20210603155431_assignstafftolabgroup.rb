class Assignstafftolabgroup < ActiveRecord::Migration[6.1]
  def change
    @labgroup = Labgroup.find_or_create_by!(name: 'Jersey')
    @labgroup.users.clear
    @labgroup.users << User.active
    @labgroup.save!
  end
end
