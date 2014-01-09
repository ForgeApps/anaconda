require 'rails/railtie'
require 'anaconda/upload_helper'

module Anaconda
  class Railtie < ::Rails::Railtie
    initializer "anaconda.upload_helper" do
      ActionView::Base.send :include, UploadHelper
    end
  end
end