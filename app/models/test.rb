class Test < ApplicationRecord
  belongs_to :plate
  belongs_to :user
  has_one_attached :result_file
  validates_uniqueness_of :plate_id
  validates :result_file, presence: true, blob: { content_type: ['text/csv', 'application/vnd.ms-excel', 'application/zip'] }
  validates_with AntivirusValidator, attribute_name: :result_file
  validates_with LabgroupValidator
  has_many :test_results, dependent: :destroy
  accepts_nested_attributes_for :test_results
  # find all tests where the plates LAB id is the current lab
  scope :by_lab, ->(lab) { joins(plate: [:lab]).where(plates: { labs: { id: lab.id } } ) }


  def auto_retest!
    Sample.transaction do
      @retest_samples = plate.samples.where(control: false, is_retest: false).includes(:client, well: [:test_result]).where(client: {autoretest: true}).where(well: {test_results: {state: [TestResult.states[:positive], TestResult.states[:lowpositive], TestResult.states[:inconclusive]]}})
      @retest_samples.each do |s|
        if [TestResult.states[:positive], TestResult.states[:lowpositive]].include? TestResult.states[s.test_result.state]
          s.create_retest(Rerun::POSITIVE)
        else
          s.create_retest(Rerun::INCONCLUSIVE)
        end
      end
    end
  end
end
