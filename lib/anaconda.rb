require 'anaconda/anaconda'
require 'anaconda/anaconda_for'
require 'anaconda/railtie' if defined?(Rails)
require 'anaconda/engine' if defined?(Rails)
require 'anaconda/version'

ActiveSupport.on_load(:active_record) do
  include Anaconda::Model
end
