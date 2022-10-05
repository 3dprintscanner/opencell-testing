class Rerun < ApplicationRecord
  POSITIVE = "Positive"
  INCONCLUSIVE = "Inconclusive"
  FAILURE = "Failure"

  REASONS = [POSITIVE, INCONCLUSIVE, FAILURE]

  belongs_to :source_sample, class_name: "Sample", foreign_key: :sample_id
  belongs_to :retest, class_name: "Sample", foreign_key: :retest_id
  accepts_nested_attributes_for :retest
  validates :reason, presence: true, inclusion: {in: REASONS}
  
end
