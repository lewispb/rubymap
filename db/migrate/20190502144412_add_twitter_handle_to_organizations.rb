class AddTwitterHandleToOrganizations < ActiveRecord::Migration[5.2]
  def change
    add_column :organizations, :twitter_handle, :string
  end
end
