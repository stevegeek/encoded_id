# frozen_string_literal: true

require "test_helper"

class EncodedId::Rails::CustomPrimaryKeyTest < Minitest::Test
  class WidgetWithFinders < Widget
    include EncodedId::Rails::ActiveRecordFinders
  end

  def setup
    Widget.delete_all
    WidgetWithIdColumn.delete_all
    @widget = Widget.create!(name: "gear")
    @other_widget = Widget.create!(name: "cog")
  end

  def teardown
    Widget.delete_all
    WidgetWithIdColumn.delete_all
  end

  def test_encoded_id_encodes_the_primary_key_value
    assert_equal Widget.encode_encoded_id(@widget.widget_id), @widget.encoded_id_hash
    assert_equal [@widget.widget_id], Widget.decode_encoded_id(@widget.encoded_id)
  end

  def test_find_by_encoded_id
    assert_equal @widget, Widget.find_by_encoded_id(@widget.encoded_id)
    assert_equal @widget, Widget.find_by_encoded_id(@widget.slugged_encoded_id)
  end

  def test_find_by_encoded_id_with_id_constraint
    assert_equal @widget, Widget.find_by_encoded_id(@widget.encoded_id, with_id: @widget.widget_id)
    assert_nil Widget.find_by_encoded_id(@widget.encoded_id, with_id: @other_widget.widget_id)
  end

  def test_find_by_encoded_id!
    assert_equal @widget, Widget.find_by_encoded_id!(@widget.encoded_id)
    assert_equal @widget, Widget.find_by_encoded_id!(@widget.encoded_id, with_id: @widget.widget_id)
    assert_raises(ActiveRecord::RecordNotFound) do
      Widget.find_by_encoded_id!(@widget.encoded_id, with_id: @other_widget.widget_id)
    end
  end

  def test_find_all_by_encoded_id
    encoded = Widget.encode_encoded_id([@widget.widget_id, @other_widget.widget_id])
    assert_equal [@widget, @other_widget].sort_by(&:widget_id), Widget.find_all_by_encoded_id(encoded).sort_by(&:widget_id)
  end

  def test_find_all_by_encoded_id!
    encoded = Widget.encode_encoded_id([@widget.widget_id, @other_widget.widget_id])
    assert_equal [@widget, @other_widget].sort_by(&:widget_id), Widget.find_all_by_encoded_id!(encoded).sort_by(&:widget_id)

    missing = Widget.encode_encoded_id([@widget.widget_id, @other_widget.widget_id + 100])
    assert_raises(ActiveRecord::RecordNotFound) { Widget.find_all_by_encoded_id!(missing) }
  end

  def test_where_encoded_id
    assert_equal [@widget], Widget.where_encoded_id(@widget.encoded_id).to_a
    assert_equal [@widget, @other_widget].sort_by(&:widget_id),
      Widget.where_encoded_id(@widget.encoded_id, @other_widget.encoded_id).to_a.sort_by(&:widget_id)
  end

  def test_active_record_finders_find
    widget = WidgetWithFinders.find(@widget.widget_id)
    assert_equal @widget.widget_id, WidgetWithFinders.find(widget.encoded_id).widget_id

    encoded = WidgetWithFinders.encode_encoded_id([@widget.widget_id, @other_widget.widget_id])
    assert_equal [@widget.widget_id, @other_widget.widget_id].sort, WidgetWithFinders.find(encoded).map(&:widget_id).sort
  end

  def test_queries_primary_key_rather_than_id_column
    widget = WidgetWithIdColumn.create!
    other = WidgetWithIdColumn.create!
    WidgetWithIdColumn.where(widget_id: widget.widget_id).update_all(["id = ?", other.widget_id])

    assert_equal widget, WidgetWithIdColumn.find_by_encoded_id(widget.encoded_id)
    assert_equal widget, WidgetWithIdColumn.find_by_encoded_id!(widget.encoded_id)
    assert_equal [widget], WidgetWithIdColumn.find_all_by_encoded_id(widget.encoded_id)
    assert_equal [widget], WidgetWithIdColumn.find_all_by_encoded_id!(widget.encoded_id)
    assert_equal [widget], WidgetWithIdColumn.where_encoded_id(widget.encoded_id).to_a
  end
end
