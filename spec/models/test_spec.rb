require 'rails_helper'

RSpec.describe Test, type: :model do
  it "should validate that a plate can only be tested once" do
    wells = build_list(:well, 96)
    @user = create(:user)
    @labgroup = create(:labgroup)
    @labgroup.users << @user
    @labgroup.save!
    @plate = create(:plate, wells: wells, lab: @labgroup.labs.first, user: @user)
    @test = create(:test, plate: @plate, user: @user)

    @test_2 = build(:test, plate: @plate, user: @user)

    expect(@test_2.save).to eq false
    expect(@test_2.errors.messages[:plate_id].first).to eq 'has already been taken'
    expect(@test_2.errors.details[:plate_id].first[:error]).to eq :taken
  end

  it "should validate that a plate needs a user" do
    wells = build_list(:well, 96)
    @user = create(:user)
    @labgroup = create(:labgroup)
    @labgroup.users << @user
    @labgroup.save!
    @plate = create(:plate, wells: wells, lab: @labgroup.labs.first, user: @user)
    @test = build(:test, plate: @plate, user: nil)

    expect(@test.save).to eq false
    expect(@test.errors.messages[:user].first).to eq 'must exist'
  end

  it "should validate that the confirming user is a member of the same labgroup that the plate user belongs to" do
    wells = build_list(:well, 96)
    @labgroup = create(:labgroup)
    @user = create(:user)
    @user_2 = create(:user)
    @labgroup.users << @user
    @labgroup.save!
    @plate = create(:plate, wells: wells, lab: @labgroup.labs.first, user: @user)
    @test = build(:test, plate: @plate, user: @user_2)

    expect(@test.save).to eq false
    expect(@test.errors.messages[:user].first).to eq 'not in labgroup'
  end

  it "should create a valid test" do
    wells = build_list(:well, 96)
    @labgroup = create(:labgroup)
    @user = create(:user)
    @labgroup.users << @user
    @labgroup.save!
    @plate = create(:plate, wells: wells, lab: @labgroup.labs.first, user: @user)
    @test = build(:test, plate: @plate, user: @user)

    expect(@test.save).to eq true
  end
end
