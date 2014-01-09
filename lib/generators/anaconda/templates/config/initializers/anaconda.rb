# Use this setup block to configure all options available in Anaconda.
Anaconda.config do |config|
  config.aws = {
    aws_access_key: ENV["AWS_ACCESS_KEY"] || nil,
    aws_secret_key: ENV["AWS_SECRET_KEY"] || nil,
    aws_bucket:     ENV["AWS_BUCKET"]     || nil
  }
end