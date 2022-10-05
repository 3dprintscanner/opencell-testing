require 'rails_helper'

RSpec.describe "plates/index", type: :view do
  before(:each) do
    wells = build_list(:well, 96)
    @lab = create(:lab, labgroups: [create(:labgroup)])
    @user = create(:user)
    @lab.labgroups.first.users << @user
    @lab.labgroups.first.save!
    @plate = create(:plate, wells: wells, lab:@lab, user: @user)
    assign(:plates, [
      @plate
    ])
  end

  it "renders a list of plates" do
    render
  end
end
