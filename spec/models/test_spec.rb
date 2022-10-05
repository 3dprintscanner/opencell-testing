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


  it "should auto retest only for approved clients" do
    wells = build_list(:well, 96)
    @labgroup = create(:labgroup)
    @user = create(:user)
    @labgroup.users << @user
    @labgroup.save!
    @plate = create(:plate, wells: wells, lab: @labgroup.labs.first, user: @user)
    
    @client = create(:client, autoretest: true)

    @well = wells.first
    Sample.with_user(@user) do
      @sample = create(:sample, well: @well, plate: @plate, client: @client)
      @sample.dispatched!
      @sample.received!
      @sample.preparing!
      @sample.prepared!
      @sample.tested!
      @test = create(:test, plate: @plate, user: @user)
      @test_result = create(:test_result, sample: @sample, well: @well, test: @test, state: TestResult.states[:positive])
    end
    
    expect(@sample.retest).to be nil
    expect(@sample.rerun).to be nil
    Sample.with_user(@user) do
      expect {@test.auto_retest! }.to change {Sample.count}.by 1
    end
    @sample.reload
    expect(@sample.rerun).to_not be nil
    expect(@sample.retest).to_not be nil
    expect(@sample.retest.is_retest).to eq true

  end

  it "should not auto retest when client doesn't have value set" do
    wells = build_list(:well, 96)
    @labgroup = create(:labgroup)
    @user = create(:user)
    @labgroup.users << @user
    @labgroup.save!
    @plate = create(:plate, wells: wells, lab: @labgroup.labs.first, user: @user)
    
    @client = create(:client, autoretest: false)

    @well = wells.first
    Sample.with_user(@user) do
      @sample = create(:sample, well: @well, plate: @plate, client: @client)
      @sample.dispatched!
      @sample.received!
      @sample.preparing!
      @sample.prepared!
      @sample.tested!
      @test = create(:test, plate: @plate, user: @user)
      @test_result = create(:test_result, sample: @sample, well: @well, test: @test, state: TestResult.states[:positive])
    end
    
    expect(@sample.retest).to be nil
    expect(@sample.rerun).to be nil
    Sample.with_user(@user) do
      expect {@test.auto_retest! }.to_not change {Sample.count}
    end
    @sample.reload
    expect(@sample.rerun).to be nil
    expect(@sample.retest).to be nil

  end

  it "should not auto retest control samples" do
    wells = build_list(:well, 96)
    @labgroup = create(:labgroup)
    @user = create(:user)
    @labgroup.users << @user
    @labgroup.save!
    @plate = create(:plate, wells: wells, lab: @labgroup.labs.first, user: @user)
    
    @client = create(:client, autoretest: true)

    @well = wells.first
    Sample.with_user(@user) do
      @sample = create(:sample, well: @well, plate: @plate, client: @client, control: true)
      @sample.dispatched!
      @sample.received!
      @sample.preparing!
      @sample.prepared!
      @sample.tested!
      @test = create(:test, plate: @plate, user: @user)
      @test_result = create(:test_result, sample: @sample, well: @well, test: @test, state: TestResult.states[:positive])
    end
    
    expect(@sample.retest).to be nil
    expect(@sample.rerun).to be nil
    Sample.with_user(@user) do
      expect {@test.auto_retest! }.to_not change {Sample.count}
    end
    @sample.reload
    expect(@sample.rerun).to be nil
    expect(@sample.retest).to be nil

  end

  it "should not auto retest samples which themselves are retests" do
    wells = build_list(:well, 96)
    @labgroup = create(:labgroup)
    @user = create(:user)
    @labgroup.users << @user
    @labgroup.save!
    @plate = create(:plate, wells: wells, lab: @labgroup.labs.first, user: @user)
    
    @client = create(:client, autoretest: true)

    @well = wells.first
    Sample.with_user(@user) do
      @sample = create(:sample, well: @well, plate: @plate, client: @client, is_retest: true)
      @sample.dispatched!
      @sample.received!
      @sample.preparing!
      @sample.prepared!
      @sample.tested!
      @test = create(:test, plate: @plate, user: @user)
      @test_result = create(:test_result, sample: @sample, well: @well, test: @test, state: TestResult.states[:positive])
    end
    
    expect(@sample.retest).to be nil
    expect(@sample.rerun).to be nil
    Sample.with_user(@user) do
      expect {@test.auto_retest! }.to_not change {Sample.count}
    end
    @sample.reload
    expect(@sample.rerun).to be nil
    expect(@sample.retest).to be nil

  end

  it "should set the correct reason for a retest when positive" do
    wells = build_list(:well, 96)
    @labgroup = create(:labgroup)
    @user = create(:user)
    @labgroup.users << @user
    @labgroup.save!
    @plate = create(:plate, wells: wells, lab: @labgroup.labs.first, user: @user)
    
    @client = create(:client, autoretest: true)

    @well = wells.first
    Sample.with_user(@user) do
      @sample = create(:sample, well: @well, plate: @plate, client: @client, is_retest: false)
      @sample.dispatched!
      @sample.received!
      @sample.preparing!
      @sample.prepared!
      @sample.tested!
      @test = create(:test, plate: @plate, user: @user)
      @test_result = create(:test_result, sample: @sample, well: @well, test: @test, state: TestResult.states[:positive])
    end
    
    expect(@sample.retest).to be nil
    expect(@sample.rerun).to be nil
    Sample.with_user(@user) do
      expect {@test.auto_retest! }.to change {Sample.count}.by 1
    end
    @sample.reload
    expect(@sample.rerun).to_not be nil
    expect(@sample.rerun.reason).to eq Rerun::POSITIVE
    expect(@sample.retest).to_not be nil

  end

  it "should set the correct reason for a retest when inconclusive" do
    wells = build_list(:well, 96)
    @labgroup = create(:labgroup)
    @user = create(:user)
    @labgroup.users << @user
    @labgroup.save!
    @plate = create(:plate, wells: wells, lab: @labgroup.labs.first, user: @user)
    
    @client = create(:client, autoretest: true)

    @well = wells.first
    Sample.with_user(@user) do
      @sample = create(:sample, well: @well, plate: @plate, client: @client, is_retest: false)
      @sample.dispatched!
      @sample.received!
      @sample.preparing!
      @sample.prepared!
      @sample.tested!
      @test = create(:test, plate: @plate, user: @user)
      @test_result = create(:test_result, sample: @sample, well: @well, test: @test, state: TestResult.states[:inconclusive])
    end
    
    expect(@sample.retest).to be nil
    expect(@sample.rerun).to be nil
    Sample.with_user(@user) do
      expect {@test.auto_retest! }.to change {Sample.count}.by 1
    end
    @sample.reload
    expect(@sample.rerun).to_not be nil
    expect(@sample.rerun.reason).to eq Rerun::INCONCLUSIVE
    expect(@sample.retest).to_not be nil

  end

  it "should retest multiple mixed samples" do
    wells = build_list(:well, 96)
    @labgroup = create(:labgroup)
    @user = create(:user)
    @labgroup.users << @user
    @labgroup.save!
    @plate = create(:plate, wells: wells, lab: @labgroup.labs.first, user: @user)
    
    @client = create(:client, autoretest: true)

    @well = wells.first
    @well_2 = wells.second
    @well_3 = wells.third
    @well_4 = wells.fourth
    Sample.with_user(@user) do
      @sample = create(:sample, well: @well, plate: @plate, client: @client)
      @sample_control = create(:sample, well: @well, plate: @plate, client: @client, control: true)
      @sample_negative = create(:sample, well: @well, plate: @plate, client: @client)
      @sample_retest = create(:sample, well: @well, plate: @plate, client: @client, is_retest: true)

      [@sample, @sample_control, @sample_negative, @sample_retest].each do |s|
        s.dispatched!
        s.received!
        s.preparing!
        s.prepared!
        s.tested!
      end
      
      @test = create(:test, plate: @plate, user: @user)
      @test_result = create(:test_result, sample: @sample, well: @well, test: @test, state: TestResult.states[:positive])
      @test_result = create(:test_result, sample: @sample_control, well: @well_2, test: @test, state: TestResult.states[:positive])
      @test_result = create(:test_result, sample: @sample_negative, well: @well_3, test: @test, state: TestResult.states[:negative])
      @test_result = create(:test_result, sample: @sample_retest, well: @well_4, test: @test, state: TestResult.states[:negative])
    end
    
    Sample.with_user(@user) do
      expect {@test.auto_retest! }.to change {Sample.count}.by 1
    end
    [@sample, @sample_control, @sample_negative, @sample_retest].each do |s|
      s.reload
    end
    expect(@sample.rerun).to_not be nil
    expect(@sample.retest).to_not be nil
    expect(@sample_control.rerun).to be nil
    expect(@sample_control.retest).to be nil
    expect(@sample_negative.rerun).to be nil
    expect(@sample_negative.retest).to be nil
    expect(@sample_retest.rerun).to be nil
    expect(@sample_retest.retest).to be nil

  end
end
