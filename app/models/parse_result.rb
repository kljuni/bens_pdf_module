class ParseResult < ApplicationRecord
  belongs_to :document

  enum :parse_status, { pending: 0, successful: 1, error: 2 }

  validates :result_data, presence: true
  validates :parse_status, presence: true
end
