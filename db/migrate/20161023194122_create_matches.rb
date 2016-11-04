class CreateMatches < ActiveRecord::Migration[5.0]
  def change
    create_table :matches do |t|
    	t.string :matchyear
		t.integer :matchday
		t.string :home_team
		t.float :home_prevision
		t.integer :home_score
		t.float :draw_prevision
		t.string :away_team
		t.float :away_prevision
		t.integer :away_score
		t.belongs_to :championnat, index: true 
		# => Chamionnat.matches Match.championnat
      	t.timestamps null: false
    end
  end
end
