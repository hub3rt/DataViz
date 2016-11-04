class WelcomeController < ApplicationController
  def index
  	@championnat = Championnat.find_by(name: "Ligue 1")
  	@matches = Match.where(championnat: @championnat).order(:matchyear).paginate(:page => params[:page], :per_page => 10)
  end
  def show

  end
end