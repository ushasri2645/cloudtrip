class CreateSeatClasses < ActiveRecord::Migration[8.0]
  def change
    create_table :seat_classes do |t|
      t.string :name, null: false
      t.timestamps
    end
  end
end
