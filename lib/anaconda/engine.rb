module Anaconda
  module Rails
    class Engine < ::Rails::Engine
      require 'jquery-fileupload-rails'
      require 'javascript_dlog-rails'
    end
  end
end