class DocumentDataImportJob < ApplicationJob
  queue_as :default

  def perform(document_data_id)
    @document_data = DocumentData.find(document_data_id)

    if import_document_data
      @document_data.import!
      notify_user(@document_data, success: true)
    else
      @document_data.fail!("Importing failed.")
      notify_user(@document_data, success: false)
    end
  end

  private

  def import_document_data
    [ true, false ].sample
  end

  def notify_user(document, success:)
    # Placeholder example method
  end
end
