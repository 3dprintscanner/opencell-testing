require 'rails_helper'

RSpec.describe "plates/show", type: :view do
  before(:each) do
    wells = build_list(:well, 96)
    @lab = create(:lab, labgroups: [create(:labgroup)])
    @user = create(:user)
    @lab.labgroups.first.users << @user
    @lab.labgroups.first.save!
    @plate = create(:plate, wells: wells, lab: @lab, user: @user)
  end

  it "renders attributes in <p>" do
    render
  end
end
