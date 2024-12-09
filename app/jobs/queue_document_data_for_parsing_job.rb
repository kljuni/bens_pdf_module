class QueueDocumentDataForParsingJob < ApplicationJob
  queue_as :default

  def perform(document_data_id)
    @document_data = DocumentData.find(document_data_id)

    # Simulate a successful Http-Client post request to parsing server
    successful_req_to_parsing_server = true

    if successful_req_to_parsing_server
      @document_data.queue_for_processing!
    else
      raise "HTTP request failed."
    end
  rescue StandardError => e
    @document_data.fail! if @document_data
    raise e
  end
end
