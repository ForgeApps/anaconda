require 'rails/generators'

module Anaconda
  class MigrationGenerator < ::Rails::Generators::NamedBase
    desc "Create a migration for the given class name"
    source_root File.expand_path('../templates', __FILE__)

    argument :field_name, :type => :string, :default => "asset"

    def create_migration_file
      destination = "db/migrate/#{Time.now.utc.strftime('%Y%m%d%H%M%S')}_anaconda_migration_for_#{file_name}_#{field_name}.rb".gsub(" ", "")
      migration_name = "AnacondaMigrationFor#{file_name.titlecase}#{field_name.titlecase}".gsub(" ", "")
      count = nil
      i = 1
      while !Dir.glob("db/migrate/*_anaconda_migration_for_#{file_name}_#{field_name}#{count}.rb".gsub(" ", "")).empty?
        i += 1
        count = "_#{i}"
        destination = "db/migrate/#{Time.now.utc.strftime('%Y%m%d%H%M%S')}_anaconda_migration_for_#{file_name}_#{field_name}#{count}.rb".gsub(" ", "")
        migration_name = "AnacondaMigrationFor#{file_name.titlecase}#{field_name.titlecase}#{i}".gsub(" ", "")
      end
      create_file destination, <<-FILE
class #{migration_name} < ActiveRecord::Migration
  def change
    add_column :#{plural_name}, :#{field_name}_filename, :string
    add_column :#{plural_name}, :#{field_name}_file_path, :text
    add_column :#{plural_name}, :#{field_name}_size, :integer
    add_column :#{plural_name}, :#{field_name}_original_filename, :text
    add_column :#{plural_name}, :#{field_name}_stored_privately, :boolean
    add_column :#{plural_name}, :#{field_name}_type, :string
  end
end
FILE
    end
  end
end
