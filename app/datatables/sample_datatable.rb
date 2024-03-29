require 'forwardable'

class SampleDatatable < AjaxDatatablesRails::ActiveRecord

  extend Forwardable

  def_delegators :@view, :get_badge, :button_tag, :policy_scope, :link_to

  def initialize(params, opts = {})
    @view = opts[:view_context]
    @labgroup = opts[:labgroup]
    super
  end

  def view_columns
    # Declare strings in this format: ModelName.column_name
    # or in aliased_join_table.column_name format
    @view_columns ||= {
      id: { source: "Sample.id", searchable: false },
      uid: { source: "Sample.uid", cond: :like },
      state: { source: "Sample.state", searchable: false },
      created_at: { source: "Sample.created_at", searchable: false },
      updated_at: { source: "Sample.created_at", searchable: false },
      link: { source: "Sample.link", searchable: false, orderable: false }
    }
  end

  def data
    records.map do |record|
      {
        # example:
        id: record.id,
        uid: record.uid,
        state: get_badge(record.state),
        created_at: record.created_at.strftime('%a %d %b %H:%M'),
        updated_at: record.updated_at.strftime('%a %d %b %H:%M'),
        link: link_to(record) { button_tag("Show", class: 'btn btn-primary') },
        DT_RowId:  record.id
      }
    end
  end

  def get_raw_records
    # insert query here
    policy_scope(Sample.labgroup(@labgroup))
  end

end
