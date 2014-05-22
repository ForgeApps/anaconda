module Anaconda
  class S3Uploader
    def initialize(options)
      @options = options.reverse_merge(
        id: "fileupload",
        aws_access_key_id: Anaconda.aws[:aws_access_key],
        aws_secret_access_key: Anaconda.aws[:aws_secret_key],
        bucket: Anaconda.aws[:aws_bucket],
        acl: "public-read",
        expiration: 10.hours.from_now.utc,
        max_file_size: 500.megabytes,
        as: "file"
      )
    end

    def form_options
      {
        id: @options[:id],
        method: "post",
        authenticity_token: false,
        multipart: true,
        data: {
          post: @options[:post],
          as: @options[:as],
          base_key: base_key
        }
      }
    end

    def fields
      {
        :key => key,
        :acl => @options[:acl],
        "Content-Type" => "application/octet-stream",
        :policy => policy,
        :signature => signature,
        "AWSAccessKeyId" => @options[:aws_access_key_id],
      }
    end

    def key
      @key ||= "#{base_key}/${filename}"
    end

    def base_key
      @options[:base_key]
    end

    def url
      "https://#{Anaconda.aws[:aws_endpoint]}/"
    end

    def policy
      Base64.encode64(policy_data.to_json).gsub("\n", "")
    end

    def policy_data
      {
        expiration: @options[:expiration],
        conditions: [
          #["starts-with", "$utf8", ""],
          ["starts-with", "$key", base_key],
          ["starts-with", "$Content-Type", ""],
          ["content-length-range", 1, @options[:max_file_size]],
          {bucket: @options[:bucket]},
          {acl: @options[:acl]}
        ]
      }
    end

    def signature
      Base64.encode64(
        OpenSSL::HMAC.digest(
          OpenSSL::Digest.new('sha1'),
          @options[:aws_secret_access_key], policy
        )
      ).gsub("\n", "")
    end
  end
end