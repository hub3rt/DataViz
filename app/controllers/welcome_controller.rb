class WelcomeController < ApplicationController
  def index
  	@championnat = Championnat.find_by(name: "Ligue 1")
  	@matches = Match.where(championnat: @championnat).order(:matchday).paginate(:page => params[:page], :per_page => 5)
  end
  def show

  end
end
