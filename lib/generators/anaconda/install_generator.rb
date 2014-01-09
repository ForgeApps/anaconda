require 'rails/generators'

module Anaconda
  class MigrationGenerator < ::Rails::Generators::NamedBase
    desc "Create a migration for the given model name"
    source_root File.expand_path('../templates', __FILE__)

    def create_migration_file
      puts "Received #{file_name} as the named base"
      # template "config/initializers/anaconda.rb"
    end
  end
end
