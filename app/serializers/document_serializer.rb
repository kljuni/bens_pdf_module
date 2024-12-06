class DocumentSerializer < ActiveModel::Serializer
  attributes :id, :original_filename, :upload_date, :state, :parse_status

  belongs_to :parse_result

  def parse_status
    object.parse_result.present? ? object.parse_result.parse_status : "Not parsed"
  end
end
