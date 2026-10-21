class AddDetailsToOrganizations < ActiveRecord::Migration[8.1]
  def change
    add_column :organizations, :description, :text
    add_column :organizations, :photo, :string
    add_column :organizations, :logo, :string
    add_column :organizations, :source, :string
  end
end
