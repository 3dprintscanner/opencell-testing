require 'rails_helper'

RSpec.describe "labs/index", type: :view do
  before(:each) do
    @labgroup = create(:labgroup)
    assign(:labs, [
      create(:lab, labgroups: [@labgroup]),
      create(:lab, labgroups: [@labgroup])
    ])
  end

  it "renders a list of labs" do
    render
  end
end
