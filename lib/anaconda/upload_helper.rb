module Anaconda
  # Vastly inspired by http://railscasts.com/episodes/383-uploading-to-amazon-s3
  module UploadHelper
    def anaconda_uploader_form_for(instance, attribute, form_options = {})
      a_class = instance.class unless instance.kind_of? Class
      options = a_class.anaconda_options.dup
      options[:base_key] = instance.send(options[:base_key].to_s) if options[:base_key].kind_of? Symbol
      render(:template =>"anaconda/_uploader_form_for.html.haml", :locals => {resource: instance, options: options.merge(as: attribute, form_options: form_options)}, layout: false).to_s
    end
    def anaconda_uploader_form(options = {}, &block)
      uploader = S3Uploader.new(options)
      form_tag(uploader.url, uploader.form_options) do
        uploader.fields.map do |name, value|
          hidden_field_tag(name, value)
        end.join.html_safe + file_field_tag("file").html_safe# + capture(&block)
      end
    end

    class S3Uploader
      def initialize(options)
        @options = options.reverse_merge(
          id: "fileupload",
          aws_access_key_id: Anaconda.aws[:aws_access_key],
          aws_secret_access_key: Anaconda.aws[:aws_secret_key],
          bucket: Anaconda.aws[:aws_bucket],
          acl: "public-read",
          expiration: 10.hours.from_now,
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
        "https://s3.amazonaws.com/#{@options[:bucket]}/"
      end

      def policy
        Base64.encode64(policy_data.to_json).gsub("\n", "")
      end

      def policy_data
        {
          expiration: @options[:expiration],
          conditions: [
            ["starts-with", "$utf8", ""],
            ["starts-with", "$key", base_key],
            ["content-length-range", 1, @options[:max_file_size]],
            {bucket: @options[:bucket]},
            {acl: @options[:acl]}
          ]
        }
      end

      def signature
        Base64.encode64(
          OpenSSL::HMAC.digest(
            OpenSSL::Digest::Digest.new('sha1'),
            @options[:aws_secret_access_key], policy
          )
        ).gsub("\n", "")
      end
    end
  end
end