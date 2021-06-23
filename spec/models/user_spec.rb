require 'rails_helper'

RSpec.describe User, type: :model do
  it 'should not create an user with an invalid email address' do
    @user = build(:user, email: "invalidemailaddress")
    expect(@user.save).to eq false
    expect(@user.errors[:email]).to include("is invalid")
  end

  it 'should  create an user with a valid email address' do
    @user = build(:user, email: "valid@email.com")
    expect(@user.save).to eq true
  end


  it "should disassociate user from lab groups when deactivating" do
    @labgroup = create(:labgroup)
    @user = create(:user, labgroups: [@labgroup])
    @user.deactivate!
    
    expect(@user.active).to eq false
    expect(Labgroup.find(@labgroup.id)).to_not be nil
  end
  
end