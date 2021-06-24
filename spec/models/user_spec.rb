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
    expect(@user.labgroups.size).to eq 1

    expect {
      @user.deactivate!
    }.to_not change(Labgroup, :count)
    
    expect(@user.is_active).to eq false
    expect(@user.labgroups.size).to eq 0
  end

  it "should not throw if the user has no associations" do
    
    @user = create(:user, labgroups: [])
    expect {
      @user.deactivate!
    }.to_not change(Labgroup, :count)
    
    expect(@user.is_active).to eq false
    expect(@user.labgroups.size).to eq 0
  end
  
end