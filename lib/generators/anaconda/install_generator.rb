require 'rails/generators'

module Anaconda
  class InstallGenerator < ::Rails::Generators::Base
    desc "Copy Anaconda default files"
    source_root File.expand_path('../templates', __FILE__)

    def copy_config
      template "config/initializers/anaconda.rb"
    end
  end
end
