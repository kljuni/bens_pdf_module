class Document < ApplicationRecord
  include AASM

  has_one :parse_result, dependent: :destroy
  belongs_to :user

  aasm :state do
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
      transitions from: [ :queued, :processing ], to: :failed
    end
  end
end
