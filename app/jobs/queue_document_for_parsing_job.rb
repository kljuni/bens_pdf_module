class QueueDocumentForParsingJob < ApplicationJob
  queue_as :default

  def perform(document_id)
    document = Document.find(document_id)

    # Simulate a successful response without making an HTTP request
    success = true

    if success
      Rails.logger.error("Failed ---------------------")
      document.queue_for_processing!
      Rails.logger.error("#{document.state}")
      Rails.logger.error("DONE ---------------------")
    else
      raise "HTTP request failed."
    end
  rescue StandardError => e
    document.fail! if document
    raise e
  end
end
