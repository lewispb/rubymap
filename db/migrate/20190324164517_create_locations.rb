class CreateLocations < ActiveRecord::Migration[5.2]
  def change
    create_table :locations do |t|
      t.string :address
      t.references :organization, foreign_key: true
      t.st_point :coords, geographic: true

      t.timestamps
    end
  end
end
