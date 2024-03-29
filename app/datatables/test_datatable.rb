require 'forwardable'

class TestDatatable < AjaxDatatablesRails::ActiveRecord

  extend Forwardable

  def_delegators :@view, :get_badge, :button_tag, :policy_scope, :link_to, :rails_blob_path

  def initialize(params, opts = {})
    @view = opts[:view_context]
    @lab = opts[:lab]
    @state = opts[:state]
    super
  end

  def view_columns
    # Declare strings in this format: ModelName.column_name
    # or in aliased_join_table.column_name format
    @view_columns ||= {
      id: { source: "Test.id", cond: :eq },
      plate_id: { source: "Test.plate_id"},
      created_at: { source: "Test.created_at" },
      tested_by: { source: "User.email" },
      link: {source: "Test.link", searchable: false, orderable: false },
      result_file: {source: "Test.result_file.name", searchable: false, orderable: false },
    }
  end

  def data
    records.map do |record|
      {
        # example:
        id: record.id,
        plate_id: record.plate&.id,
        created_at: record.created_at.strftime('%a %d %b %H:%M'),
        tested_by: record.user.email,
        result_file: link_to(rails_blob_path(record.result_file, disposition: "attachment")) { button_tag("Results", class: 'btn btn-info') },
        link: link_to(record.plate) { button_tag("Show", class: 'btn btn-primary') },
        DT_RowId:  record.id
      }
    end
  end

  def get_raw_records
    # insert query here
    policy_scope(Test.by_lab(@lab).includes(:result_file_attachment, :user, :plate).where(plates: { state: @state }))
  end

end