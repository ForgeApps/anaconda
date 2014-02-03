# Use this setup block to configure all options available in Anaconda.
Anaconda.config do |config|
  config.aws = {
    aws_access_key: ENV["AWS_ACCESS_KEY"] || nil,
    aws_secret_key: ENV["AWS_SECRET_KEY"] || nil,
    aws_bucket:     ENV["AWS_BUCKET"]     || nil
  }
  config.file_types = {
    audio:    /(\.|\/)(wav|mp3|m4a|aiff|ogg|flac)$/,
    video:    /(\.|\/)(mp[e]?g|mov|avi|mp4|m4v)$/,
    image:    /(\.|\/)(jp[e]?g|png|bmp)$/,
    resource: /(\.|\/)(pdf|ppt[x]?|doc[x]?|xls[x]?)$/,
  }
end