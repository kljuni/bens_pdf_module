class CreatePdfProcessingModule < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :username, null: false

      t.timestamps
    end

    add_index :users, :username, unique: true

    create_table :documents do |t|
      t.references :user, null: false, foreign_key: true
      t.string :original_filename, null: false
      t.string :stored_name, null: false
      t.string :document_hash, null: false
      t.string :state, null: false, default: 'uploaded'
      t.timestamp :upload_date, default: -> { 'CURRENT_TIMESTAMP' }
      t.boolean :import_called, default: false
      t.binary :pdf_data, null: false

      t.timestamps
    end

    create_table :parse_results do |t|
      t.references :document, null: false, foreign_key: true
      t.jsonb :result_data, null: false, default: '{}'
      t.integer :parse_status, null: false, default: 0
      t.text :error_message, null: true

      t.timestamps
    end

    add_index :documents, :stored_name, unique: true
    add_index :documents, :document_hash, unique: true
    add_index :documents, :state

    execute <<-SQL
      ALTER TABLE documents
      ADD CONSTRAINT check_state
      CHECK (state IN ('uploaded', 'queued', 'processing', 'parsed', 'imported', 'failed'));
    SQL
  end
end
