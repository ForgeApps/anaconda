require 'rails/railtie'
require 'anaconda/form_builder_helpers'

module Anaconda
  class Railtie < ::Rails::Railtie
    initializer "anaconda.upload_helper" do
      ActionView::Helpers::FormBuilder.send :include, FormBuilderHelpers
      SimpleForm::FormBuilder.send :include, FormBuilderHelpers if SimpleForm::FormBuilder
    end
  end
end