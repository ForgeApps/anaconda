# Use this setup block to configure all options available in Anaconda.
Anaconda.config do |config|
  config.aws = {
    aws_access_key: ENV["AWS_ACCESS_KEY"] || nil,
    aws_secret_key: ENV["AWS_SECRET_KEY"] || nil,
    aws_bucket:     ENV["AWS_BUCKET"]     || nil
  }
  config.file_types = {
    audio:    /(\.|\/)(wav|mp3|m4a|aiff|ogg|flac)$/i,
    video:    /(\.|\/)(mp[e]?g|mov|avi|mp4|m4v)$/i,
    image:    /(\.|\/)(jp[e]?g|png|bmp)$/i,
    resource: /(\.|\/)(pdf|ppt[x]?|doc[x]?|xls[x]?)$/i,
  }
end