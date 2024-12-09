class CreatePdfProcessingModule < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :username, null: false

      t.timestamps
    end

    add_index :users, :username, unique: true

    create_table :document_data do |t|
      t.string :document_hash, null: false
      t.binary :pdf_data, null: false
      t.jsonb :result_data, null: true, default: nil
      t.string :parse_state, null: false, default: 'uploaded'
      t.integer :parse_result_status, null: false, default: 0
      t.boolean :import_called, default: false
      t.text :failed_state_reason, null: true
      t.text :parse_error_message, null: true

      t.timestamps
    end

    add_index :document_data, :document_hash, unique: true

    create_table :documents do |t|
      t.references :user, null: false, foreign_key: true
      t.references :document_data, null: false, foreign_key: true
      t.string :original_filename, null: false
      t.string :stored_name, null: false

      t.timestamps
    end


    add_index :documents, :stored_name, unique: true

    execute <<-SQL
      ALTER TABLE document_data
      ADD CONSTRAINT check_state
      CHECK (parse_state IN ('uploaded', 'queued', 'processing', 'parsed', 'imported', 'failed'));
    SQL
  end
end
