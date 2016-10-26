# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)


def filldb(equipes, chances, scores, ligue1)
	for i in (1..10) do
		for k in (0..5) do
			Match.create(
			matchday: i,
			home_team: equipes[rand(0..8)],
			home_prevision: chances[rand(0..chances.length-1)],
			home_score: scores[rand(0..7)],
			away_team: equipes[rand(0..8)],
			away_prevision: chances[rand(0..chances.length-1)],
			away_score: scores[rand(0..7)],
			draw_prevision: chances[rand(0..chances.length-1)],
			championnat: ligue1
			)
		end
	end
end

ligue1 = Championnat.create(name:"Ligue 1")
ligue2 = Championnat.create(name:"Ligue 2")

championnats=[ligue1, ligue2]
scores=[0,0,0,1,1,2,3,4]
equipes=["ASSE", "Bordeaux", "PSG", "Lyon", "Marseille", "Monaco", "Nantes", "Montpellier", "Evian TG"]
chances=[5.0,10.0,15.0,20.0,25.0,30.0,35.0,40.0,45.0,55.0,60.0,65.0,70.0,75.0,80.0,85.0,90.0,95.0]


filldb(equipes, chances, scores, ligue1)