class DocumentSerializer < ActiveModel::Serializer
  attributes :id, :original_filename, :upload_date, :parse_state, :parse_result_status

  def parse_state
    object.document_data.parse_state
  end

  def upload_date
    object.created_at
  end

  def parse_result_status
    object.document_data.parse_result_status
  end
end
