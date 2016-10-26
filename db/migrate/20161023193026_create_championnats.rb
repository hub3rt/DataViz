class CreateChampionnats < ActiveRecord::Migration[5.0]
  def change
    create_table :championnats do |t|
		t.string :name
      	t.timestamps null: false
    end
  end
end
