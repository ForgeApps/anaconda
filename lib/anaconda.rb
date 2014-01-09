require 'anaconda/anaconda'
require 'anaconda/anaconda_for'
require 'anaconda/railtie'
require 'anaconda/engine'
require 'anaconda/version'

ActiveSupport.on_load(:active_record) do
  include Anaconda::Model
end
