class DocumentImportJob < ApplicationJob
  queue_as :default

  def perform(document_id)
    @document = Document.find(document_id)

    if @document.parsed? && !@document.import_called
      if import_document
        @document.import
      else
        @document.fail
      end
    else
      @document.fail
    end
  end

  private

  def import_document
    [ true, false ].sample
  end
end
