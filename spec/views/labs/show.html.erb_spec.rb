require 'rails_helper'

RSpec.describe "labs/show", type: :view do
  before(:each) do
    @group = create(:labgroup)
    @lab = create(:lab, labgroups: [@group])
  end

  it "renders attributes in <p>" do
    render
  end
end
