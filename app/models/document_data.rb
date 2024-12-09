class DocumentData < ApplicationRecord
  include AASM

  has_many :documents

  attribute :parse_result_status, :integer
  attribute :parse_state, :string

  enum :parse_result_status, { pending: 0, successful: 1, error: 2 }

  validates :document_hash, presence: true, uniqueness: true
  validates :pdf_data, presence: true
  validates :parse_result_status, presence: true

  aasm :parse_state do
    state :uploaded, initial: true
    state :queued, :processing, :parsed, :imported, :failed

    event :queue_for_processing do
      transitions from: :uploaded, to: :queued
    end

    event :start_processing do
      transitions from: :queued, to: :processing
    end

    event :mark_as_parsed do
      transitions from: :processing, to: :parsed
    end

    event :import do
      transitions from: :parsed, to: :imported
    end

    event :fail do
      transitions from: [ :uploaded, :queued, :processing, :parsed, :imported ], to: :failed do
        after do |reason|
          self.update!(failed_state_reason: reason)
        end
      end
    end
  end
end
