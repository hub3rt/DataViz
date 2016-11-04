require_relative 'boot'

require 'rails/all'
require 'rserve'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module InitRails
  class Application < Rails::Application
  	config.time_zone = "Europe/Paris"
  	config.assets.paths << Rails.root.join("public", "assets", "stylesheets")
   	config.assets.paths << Rails.root.join("public", "assets", "javascripts")

	config.filter_parameters << :password
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
  end
end
