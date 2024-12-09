class Document < ApplicationRecord
  belongs_to :user
  belongs_to :document_data
end
