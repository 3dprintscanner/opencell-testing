require 'rails_helper'
RSpec.describe Plate, type: :model do
  describe 'class_scopes' do
    it "should scope plates by the current lab" do
      @user = create(:user)
      @labgroup = create(:labgroup)
      @labgroup.users << @user
      @labgroup.save!
      @labgroup_2 = create(:labgroup)
      @labgroup_2.users << @user
      @labgroup_2.save!
      plate =  Plate.build_plate
      plate.lab = @labgroup.labs.first
      plate.user = @user
      plate.save!

      plate_2 =  Plate.build_plate
      plate_2.lab = @labgroup_2.labs.first
      plate_2.user = @user
      plate_2.save!
      expect(Plate.by_lab(@labgroup.labs.first).size).to eq 1
      expect(Plate.all.size).to eq 2
    end

    it "should scope plates by the current lab if in the same labgroup" do
      @user = create(:user)
      @labgroup = create(:labgroup)
      @labgroup.labs << create(:lab)
      @labgroup.users << @user
      @labgroup.save!
      plate =  Plate.build_plate
      plate.lab = @labgroup.labs.first
      plate.user = @user
      plate.save!

      plate_2 =  Plate.build_plate
      plate_2.lab = @labgroup.labs.second
      plate_2.user = @user
      plate_2.save!
      expect(Plate.by_lab(@labgroup.labs.first).size).to eq 1
      expect(Plate.by_lab(@labgroup.labs.first).first).to eq plate
      expect(Plate.by_lab(@labgroup.labs.second).size).to eq 1
      expect(Plate.by_lab(@labgroup.labs.second).first).to eq plate_2
      expect(Plate.all.size).to eq 2
    end
  end
  describe "build_plate" do
    before :each do
      @user = create(:user)
      @labgroup = create(:labgroup)
      @labgroup.users << @user
      @labgroup.save!
    end

    it "Should create a valid plate with valid number of empty wells" do
      plate =  Plate.build_plate
      plate.lab = @labgroup.labs.first
      plate.user = @user
      expect(plate.save).to be true
      expect(plate.wells.size).to be 96
      expect(plate.samples.size).to be 0
    end

    it "Should validate the plate user is in the associated labgroup" do
      plate =  Plate.build_plate
      plate.lab = @labgroup.labs.first
      plate.user = create(:user)
      expect(plate.save).to be false
      expect(plate.errors.size).to eq 1
      expect(plate.errors[:user].size).to eq 1
      expect(plate.errors[:user].first).to eq 'not in labgroup'
    end

    it "Should create a valid plate with a correct UID" do
      plate =  Plate.build_plate
      plate.lab = @labgroup.labs.first
      plate.user = @user
      expect(plate.save).to be true
      expect(plate.uid).to eq "#{Date.today}-#{plate.id}"
    end

    it "Should not create a valid plate with no user" do
      plate =  Plate.build_plate
      lab = create(:lab)
      plate.user = nil
      plate.lab = lab
      expect(plate.save).to be false
      expect(plate.errors.size).to be 2
      expect(plate.errors[:user].first).to eq "must exist"
      expect(plate.errors[:user].second).to eq "not in labgroup"
    end

    it "Should not create a valid plate with no lab" do
      plate =  Plate.build_plate
      plate.user = @user
      plate.lab = nil
      expect(plate.save).to be false
      expect(plate.errors.size).to be 1
      expect(plate.errors[:lab].first).to eq "must exist"
    end

    it "Should not create a plate with insufficient wells" do
      plate =  Plate.new
      plate.lab = @labgroup.labs.first
      plate.user = @user
      wells = []
      PlateHelper.columns.first(11).each do |col|
        PlateHelper.rows.each do |row|
          wells << Well.new(row: row, column: col, plate: plate)
        end
      end
      expect(plate.save).to be false
      expect(plate.errors.size).to eq 1
      expect(plate.errors[:wells].size).to eq 1
      expect(plate.errors[:wells].first.include? 'too short')
    end

    it "Should not create a plate with insufficient wells" do
      plate =  Plate.new
      plate.lab = @labgroup.labs.first
      plate.user = @user
      wells = []
      PlateHelper.columns.to_a.concat([13]).each do |col|
        PlateHelper.rows.each do |row|
          wells << Well.new(row: row, column: col, plate: plate)
        end
      end
      expect(plate.save).to be false
      expect(plate.errors.size).to eq 1
      expect(plate.errors[:wells].size).to eq 1
      expect(plate.errors[:wells].first.include? 'too long')
    end

    it "Should not create a plate with duplicate wells" do
      plate =  Plate.new
      plate.lab = @labgroup.labs.first
      plate.user = @user
      wells = []
      # should create G1-12
      ('A'..'G').to_a.concat(['G']).each do |row|
        PlateHelper.columns.each do |col|
          wells << Well.new(row: row, column: col, plate: plate)
        end
      end
      plate.wells = wells
      expect(plate.save).to be false
      expect(plate.errors.size).to eq 1
      expect(plate.errors[:wells].size).to eq 1
      expect(plate.errors[:wells].first.include? 'Duplicate Well')
    end
  end

  describe "Assign Samples" do

    before :each do
      @user = create(:user)
      @labgroup = create(:labgroup)
      @labgroup.users << @user
      @labgroup.save!

    end

    it "should assign a valid sample to a well on a plate" do
      Sample.with_user(@user) do
        plate = Plate.build_plate
        plate.lab = @labgroup.labs.first
        plate.user = @user
        @sample = create(:sample, state: Sample.states[:received])
        sample_mappings = [{id: @sample.id, row: plate.wells.third.row, column: plate.wells.third.column}]
        this_plate = plate.assign_samples(sample_mappings)
        expect(this_plate.save).to be true
        expect(this_plate.wells.third.sample).to eq @sample.reload
        expect(Sample.states[this_plate.wells.third.sample.state]).to eq Sample.states[:preparing]
      end
    end

    it "should not be able to assign a sample to 2 wells" do

      Sample.with_user(@user) do
        plate = Plate.build_plate
        plate.lab = @labgroup.labs.first
        plate.user = @user
        @sample = create(:sample, state: Sample.states[:received])
        sample_mappings = [ {id: @sample.id, row: plate.wells.third.row, column: plate.wells.third.column}, {id: @sample.id, row: plate.wells.second.row, column: plate.wells.second.column} ]
        this_plate = plate.assign_samples(sample_mappings)
        expect(this_plate.save).to be false
        expect(this_plate.errors.size).to eq 1
        expect(this_plate.errors[:plate].size).to eq 1
        expect(this_plate.errors[:plate].first.include? 'Duplicate Sample In plate Found')
      end
    end

    it "should handle a nil sample id" do
      Sample.with_user(@user) do
        plate = Plate.build_plate
        plate.lab = @labgroup.labs.first
        plate.user = @user
        @sample = create(:sample, state: Sample.states[:received])
        sample_mappings = [{id: nil, row: plate.wells.third.row, column: plate.wells.third.column, control: false}]
        this_plate = plate.assign_samples(sample_mappings)
        expect(this_plate.save).to be true
        expect(this_plate.wells.third.sample).to be nil
      end
    end

    it "should handle an empty sample id" do
      Sample.with_user(@user) do
        plate = Plate.build_plate
        plate.lab = @labgroup.labs.first
        plate.user = @user
        sample_mappings = [{id: "", row: plate.wells.third.row, column: plate.wells.third.column, control: false}]
        this_plate = plate.assign_samples(sample_mappings)
        expect(this_plate.save).to be true
        expect(this_plate.wells.third.sample).to be nil
      end
    end

    it "should throw on a nil row" do
      Sample.with_user(@user) do
        plate = Plate.build_plate
        plate.lab = @labgroup.labs.first
        plate.user = @user
        @sample = create(:sample, state: Sample.states[:received])
        sample_mappings = [{id: @sample.id, row: nil, column: plate.wells.third.column}]
        expect(plate.assign_samples(sample_mappings).assign_error).to be true
        expect(plate.assign_samples(sample_mappings).valid?).to be false
      end
    end

    it "should throw on a nil column" do
      Sample.with_user(@user) do
        plate = Plate.build_plate
        plate.lab = @labgroup.labs.first
        plate.user = @user
        @sample = create(:sample, state: Sample.states[:received])
        sample_mappings = [{id: @sample.id, row: plate.wells.third.row, column: nil}]
        expect(plate.assign_samples(sample_mappings).assign_error).to be true
        expect(plate.assign_samples(sample_mappings).valid?).to be false
      end
    end

    it "should handle a valid control sample" do
      Sample.with_user(@user) do
        plate = Plate.build_plate
        plate.lab = @labgroup.labs.first
        plate.user = @user
        @sample = create(:sample, state: Sample.states[:received])
        control_position = PlateHelper.control_positions.first
        sample_mappings = [{id: nil, column: control_position[:col], row: control_position[:row], control: true, control_code: Sample::CONTROL_CODE}]
        expect(plate.assign_samples(sample_mappings).valid?).to be true
      end
    end

    it "should reject an invalid control sample" do
      Sample.with_user(@user) do
        plate = Plate.build_plate
        plate.lab = @labgroup.labs.first
        plate.user = @user
        @sample = create(:sample, state: Sample.states[:received])
        control_position = PlateHelper.control_positions.first
        sample_mappings = [{id: nil, column: control_position[:col], row: control_position[:row], control: true, control_code: 'WRONG CODE'}]
        expect(plate.assign_samples(sample_mappings).valid?).to be false
      end
    end
  end

end
