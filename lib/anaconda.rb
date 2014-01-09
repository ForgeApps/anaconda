require 'rails'
require 'anaconda/anaconda'
require 'anaconda/anaconda_for'
require 'anaconda/railtie'
require 'anaconda/engine'
require 'anaconda/version'

ActiveSupport.on_load(:active_record) do
  include Anaconda::Model
end

module Anaconda
  mattr_accessor :aws
  @@aws = {
    aws_access_key: "",
    aws_secret_key: "",
    aws_bucket:     ""
  }

  # Default way to setup Anaconda. Run rails generate anaconda:install
  # to create a fresh initializer with all configuration values.
  def self.config
    yield self
  end
end