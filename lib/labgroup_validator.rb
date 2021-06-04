class LabgroupValidator < ActiveModel::Validator
  def validate(record)

    @lab = record.plate.lab
    testing_user = record.user

    labgroup_users = @lab.labgroups.flat_map { |l| l.users }

    return unless !labgroup_users.include? testing_user

    record.errors.add(:user, 'not in labgroup')   
  end
end