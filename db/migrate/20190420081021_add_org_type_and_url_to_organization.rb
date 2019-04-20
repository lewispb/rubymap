class AddOrgTypeAndUrlToOrganization < ActiveRecord::Migration[5.2]
  def change
    add_column :organizations, :org_type, :string
    add_column :organizations, :url, :string
  end
end
