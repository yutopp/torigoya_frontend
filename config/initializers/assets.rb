# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
# Rails.application.config.assets.precompile += %w( search.js )
#Rails.application.config.assets.precompile += %w( procgarden.js )
Rails.application.config.assets.precompile += ['*.js', '*.css', '*.css.erb']

Rails.application.config.assets.precompile += %w( select2/select2.png )
Rails.application.config.assets.precompile += %w( select2/select2-spinner.gif )
Rails.application.config.assets.precompile += %w( select2/select2x2.png )

Rails.application.config.assets.precompile += %w( jquery-ui/themes/* )
