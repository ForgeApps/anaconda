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
    audio:    /(\.|\/)(wav|mp3|m4a|aiff|ogg|flac)$/,
    video:    /(\.|\/)(mp[e]?g|mov|avi|mp4|m4v)$/,
    image:    /(\.|\/)(jp[e]?g|png|bmp)$/,
    resource: /(\.|\/)(pdf|ppt[x]?|doc[x]?|xls[x]?)$/,
  }

  # Default way to setup Anaconda. Run rails generate anaconda:install
  # to create a fresh initializer with all configuration values.
  def self.config
    yield self
  end
  
  def self.js_file_types
    # http://stackoverflow.com/questions/4854714/how-to-translate-ruby-regex-to-javascript-i-mx-and-rails-3-0-3
    js_file_types = {}
    file_types.each do |group_name, regexp|
      str = regexp.inspect.
              sub('\\A' , '^').
              sub('\\Z' , '$').
              sub('\\z' , '$').
              sub(/^\// , '').
              sub(/\/[a-z]*$/ , '').
              gsub(/\(\?#.+\)/ , '').
              gsub(/\(\?-\w+:/ , '(').
              gsub(/\s/ , '')
        regexp_str = Regexp.new(str).source
      js_file_types[group_name.to_s] = regexp_str
    end
    return js_file_types
  end
  
  def self.remove_s3_object_in_bucket_with_file_path(bucket, file_path)
    aws = Fog::Storage.new({:provider => 'AWS', :aws_access_key_id => Anaconda.aws[:aws_access_key], :aws_secret_access_key => Anaconda.aws[:aws_secret_key], :path_style => true})
    aws.delete_object(bucket, file_path)
  end
end