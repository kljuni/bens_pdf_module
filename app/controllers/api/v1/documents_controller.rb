class Api::V1::DocumentsController < ApplicationController
  before_action :set_user
  before_action :set_document_data, only: [ :import, :download, :parse_result ]

  def create
    document = params[:document]

    if document.blank?
      render json: { error: "No document provided" }, status: :bad_request
      return
    end

    document_data = document.tempfile.read

    if document.size > 10.megabytes || File.extname(document.original_filename).downcase != ".pdf"
      render json: { error: "Document must be a PDF and less than 10MB" }, status: :unprocessable_entity
      return
    end

    document_hash = Digest::SHA256.hexdigest(document_data)
    existing_document_data = DocumentData.find_by(document_hash: document_hash)

    if existing_document_data
      document_record = @user.documents.new(
        original_filename: document.original_filename,
        stored_name: SecureRandom.uuid,
        document_data: existing_document_data
      )

      if document_record.save
        render json: document_record, status: :ok
      else
        render json: document_record.errors, status: :unprocessable_entity
      end
    else
      document_record = @user.documents.new(
        original_filename: document.original_filename,
        stored_name: "#{SecureRandom.uuid}.pdf"
      )

      document_data_record = document_record.build_document_data(
        document_hash: document_hash,
        pdf_data: document_data
      )

      if document_record.save && document_data_record.save
        QueueDocumentDataForParsingJob.perform_later(document_data_record.id)
        render json: document_record, status: :created
      else
        render json: document_record.errors, status: :unprocessable_entity
      end
    end
  end

  def index
    documents = @user.documents.includes(:document_data)
    render json: documents, each_serializer: DocumentSerializer, status: :ok
  end

  def destroy
    document = @user.documents.find_by(id: params[:id])

    if document.nil?
      render json: { error: "Document not found." }, status: :not_found
    elsif document.document_data.uploaded? || document.document_data.queued?
      document.destroy
      render json: { message: "Document removed successfully." }, status: :ok
    else
      render json: { error: "Cannot remove document after it has been sent for parsing." }, status: :forbidden
    end
  end

  def parse_result
    if @document_data.processing? && @document_data.result_data.nil?
      parse_result_params = params.require(:parse_result).permit(:parse_result_status, :parse_error_message, result_data: {})

      if @document_data.update(parse_result_params)
        @document_data.mark_as_parsed!
        render json: { message: "Document parsed." }, status: :ok
      else
        render json: { error: "Failed to update parse result: #{@document_data.errors.full_messages.join(', ')}" }, status: :unprocessable_entity
      end
    else
      render json: { error: "Document is not in a valid state for parsing" }, status: :unprocessable_entity
    end
  end

  def import
    if @document_data.imported?
      render json: { error: "Document has already been imported." }, status: :unprocessable_entity
    elsif @document_data.parsed?
      if @document_data.import_called
        render json: { error: "Import of the document already called" }, status: :unprocessable_entity
      else
        @document_data.update!(import_called: true)
        DocumentDataImportJob.perform_later(@document_data.id)
        render json: { message: "Document import process started" }, status: :accepted
      end
    else
      render json: { error: "Document must be parsed before importing" }, status: :unprocessable_entity
    end
  end

  def download
    if @document_data.queued?
      begin
        send_data @document_data.pdf_data, type: "application/pdf"
        @document_data.start_processing!
      rescue => e
        Rails.logger.error("Failed to send document: #{e.message}")
        render json: { error: "Failed to send document" }, status: :internal_server_error
      end
    else
      if @document_data.nil?
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

  def set_document_data
    @document_data = @user.documents.find(params[:id])&.document_data
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Document not found" }, status: :not_found
  end
end
