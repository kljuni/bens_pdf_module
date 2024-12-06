class Api::V1::DocumentsController < ApplicationController
  before_action :set_user
  before_action :set_document, only: [:destroy, :import]

  def create
    document = params[:document]
  
    if document.blank?
      render json: { error: "No document provided" }, status: :bad_request
      return
    end
  
    # Read document content only once
    document_data = document.tempfile.read
  
    if document.size > 10.megabytes || File.extname(document.original_filename).downcase != ".pdf"
      render json: { error: "Document must be a PDF and less than 10MB" }, status: :unprocessable_entity
      return
    end
  
    # Hash the document content for duplicate check
    document_hash = Digest::SHA256.hexdigest(document_data)
    existing_document = Document.find_by(document_hash: document_hash)
  
    if existing_document
      # Handle existing document states
      if existing_document.uploaded? || existing_document.processing? || existing_document.queued?
        render json: { error: "This document has already been uploaded and is in #{existing_document.state} state. Please wait until it's ready." }, status: :unprocessable_entity
      elsif existing_document.failed?
        render json: { error: "Document processing failed. Please try uploading again." }, status: :unprocessable_entity
      else
        # Document exists and is in a valid state, reuse its data
        document_record = @user.documents.new(
          original_filename: document.original_filename,
          stored_name: SecureRandom.uuid,
          pdf_data: document_data, # Use the previously read document data
          upload_date: Time.current,
          document_hash: document_hash,
          state: existing_document.state,
          parse_result: existing_document.parse_result
        )

        if document_record.save
          render json: document_record, status: :ok
        else
          render json: document_record.errors, status: :unprocessable_entity
        end
      end
    else
      # Document doesn't exist, create a new record
      document_record = @user.documents.new(
        original_filename: document.original_filename,
        stored_name: "#{SecureRandom.uuid}.pdf",
        pdf_data: document_data, # Use the previously read document data
        upload_date: Time.current,
        document_hash: document_hash
      )

      if document_record.save
        QueueDocumentForParsingJob.perform_later(document_record.id)
        render json: document_record, status: :created
      else
        render json: document_record.errors, status: :unprocessable_entity
      end
    end
  end


  def index
    documents = @user.documents.includes(:parse_result)
    render json: documents, each_serializer: DocumentSerializer, status: :ok
  end

  def destroy
    if @document.uploaded?
      @document.destroy
      render json: { message: "Document removed successfully" }, status: :ok
    else
      render json: { error: "Cannot remove document after it has been sent for parsing" }, status: :forbidden
    end
  end

  def update_parse_status
    document = Document.find(params[:id])

    if document.processing? && document.parse_result.nil?
      parse_result_params = params.require(:parse_result).permit(:parse_status, :error_message, result_data: {})

      parse_result = document.build_parse_result(parse_result_params)

      if parse_result.save
        document.mark_as_parsed!
        render json: { message: "Document parsed successfully" }, status: :ok
      else
        render json: { error: "Failed to update parse result: #{parse_result.errors.full_messages.join(', ')}" }, status: :unprocessable_entity
      end
    else
      render json: { error: "Document is not in a valid state for parsing" }, status: :unprocessable_entity
    end
  end

  def import
    if @document.parsed?
      if @document.import_called
        render json: { error: "Import of the document already called" }, status: :unprocessable_entity
      else
        @document.import ? render(json: { message: "Document imported successfully" }, status: :ok) :
                       render(json: { error: "Unable to import the document" }, status: :unprocessable_entity)
      end
    else
      render json: { error: "Document must be parsed before importing" }, status: :unprocessable_entity
    end
  end

  def download
    document = Document.find_by(id: params[:id])

    if document&.queued?
      begin
        send_data document.pdf_data, type: "application/pdf", filename: "#{document.original_filename}"
        document.start_processing!
      rescue => e
        Rails.logger.error("Failed to send document: #{e.message}")
        render json: { error: "Failed to send document" }, status: :internal_server_error
      end
    else
      if document.nil?
        render json: { error: "Document not found" }, status: :not_found
      else
        render json: { error: "Document is not in a valid state for download" }, status: :unprocessable_entity
      end
    end
  end

  private

  def set_user
    @user = User.find_by(id: params[:user_id]) || User.first

    if @user.nil?
      render json: { error: "No users found in the system" }, status: :not_found
    end
  end


  def set_document
    @document = @user.documents.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Document not found" }, status: :not_found
  end
end
