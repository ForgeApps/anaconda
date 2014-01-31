require 'rails'
require 'anaconda/anaconda'
require 'anaconda/errors'
require 'anaconda/anaconda_for'
require 'anaconda/railtie'
require 'anaconda/engine'
require 'anaconda/version'

ActiveSupport.on_load(:active_record) do
  include Anaconda::Model
end

module Anaconda
  mattr_accessor :aws, :file_types
  @@aws = {
    aws_access_key: "",
    aws_secret_key: "",
    aws_bucket:     ""
  }
  
  @@file_types = {
    audio:    /(\.|\/)(wav|mp3|m4a|aiff|ogg|flac)$/i,
    video:    /(\.|\/)(mp[e]?g|mov|avi|mp4|m4v)$/i,
    image:    /(\.|\/)(jp[e]?g|png|bmp)$/i,
    resource: /(\.|\/)(pdf|ppt[x]?|doc[x]?|xls[x]?)$/i,
  }

  # Default way to setup Anaconda. Run rails generate anaconda:install
  # to create a fresh initializer with all configuration values.
  def self.config
    yield self
  end
end