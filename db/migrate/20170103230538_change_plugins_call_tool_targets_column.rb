# frozen_string_literal: true

class ChangePluginsCallToolTargetsColumn < ActiveRecord::Migration[4.2]
  def change
    remove_column(:plugins_call_tools, :targets)
    add_column(:plugins_call_tools, :targets, :json, array: true, default: [])
  end
end
