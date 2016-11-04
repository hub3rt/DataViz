class MatchesController < ApplicationController
	layout'admin'
	def new
		@match = Match.new
		@championnats = Championnat.all
	end
	def create
		@match = Match.new(match_params)
		if @match.save
			redirect_to matches_path
		else
			render 'new'
		end
	end

	private	def match_params
		params.require(:match).permit(:matchday, :home_team, :home_prevision, :home_score, :draw_prevision, :away_team, :away_prevision, :away_score, :championnat_id)
	end

	def index
		@championnat = Championnat.find_by(name: "Ligue 1")
		@matches = Match.where(championnat: @championnat).order(matchyear: :asc, matchday: :asc).paginate(:page => params[:page], :per_page => 100)


	end

	def show
		@match = Match.find(params[:id])
	end

	def edit
		@match = Match.find(params[:id])
	end

	def update
		@match = Match.find(params[:id])
		if @match.update(match_params)
			redirect_to @match
		else
			render 'edit'
		end
	end
	
	def destroy
		@match = Match.find(params[:id])
		@match.destroy
		redirect_to matches_path
	end
	def launch
		# ex : PredictionJob.new.async.perform
		PredictionJob.perform_async
		redirect_to matches_path
	end

end