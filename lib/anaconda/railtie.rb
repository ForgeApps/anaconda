require 'rails/railtie'
require 'anaconda/upload_helper'

module Anaconda
  class Railtie < ::Rails::Railtie
    initializer "anaconda.upload_helper" do
      ActionView::Base.send :include, UploadHelper
      ActionView::Helpers::FormBuilder.send :include, FormBuilderHelpers
      SimpleForm::FormBuilder.send :include, FormBuilderHelpers if SimpleForm::FormBuilder
    end
  end
end