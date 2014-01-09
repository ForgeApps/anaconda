module Anaconda
  module Generators
    class InstallGenerator < Rails::Generators::Base
      desc "Copy Anaconda default files"
      source_root File.expand_path('../templates', __FILE__)

      def copy_config
        template "config/initializers/anaconda.rb"
      end

      def show_readme
        if behavior == :invoke
          readme "README"
        end
      end
    end
  end
end
