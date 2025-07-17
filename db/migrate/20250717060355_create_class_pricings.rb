class CreateClassPricings < ActiveRecord::Migration[8.0]
  def change
    create_table :class_pricings do |t|
      t.references :flight, null: false, foreign_key: true
      t.references :seat_class, null: false, foreign_key: true
      t.decimal :multiplier

      t.timestamps
    end
  end
end
