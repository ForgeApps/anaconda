module Anaconda
  module FormBuilderHelpers

    def anaconda( anaconda_field_name, form_options = {} )
      output = ""
      instance = nil
      options = {}

      element_id = "anaconda_file_#{anaconda_field_name}"

      if self.class == SimpleForm::FormBuilder
        instance = self.object
        a_class = self.object.class unless self.object.kind_of? Class

        begin
          options = a_class.anaconda_options[anaconda_field_name.to_sym].dup
        rescue
          raise AnacondaError, "attribute options not set for column #{anaconda_field_name}. Did you add `anaconda_for :#{anaconda_field_name}` to the model?"
        end
        options[:base_key] = instance.send(options[:base_key].to_s) if options[:base_key].kind_of? Symbol
        
        uploader = S3Uploader.new(options)

        output += self.input_field "file", name: "file", id: element_id, as: :file, data: {url: uploader.url, form_data: uploader.fields.to_json, media_types: Anaconda.js_file_types}
      end

      output += self.hidden_field "#{anaconda_field_name}_filename".to_sym
      output += self.hidden_field "#{anaconda_field_name}_file_path".to_sym
      output += self.hidden_field "#{anaconda_field_name}_size".to_sym
      output += self.hidden_field "#{anaconda_field_name}_original_filename".to_sym
      output += self.hidden_field "#{anaconda_field_name}_stored_privately".to_sym
      output += self.hidden_field "#{anaconda_field_name}_type".to_sym

      # output += render(:template =>"anaconda/_uploader_form_for.html.haml", :locals => {resource: instance, options: options.merge(as: anaconda_field_name, form_options: form_options, element_id: element_id )}, layout: false).to_s

      options = options.merge(as: anaconda_field_name, form_options: form_options, element_id: element_id )

      output += <<-END
<div id="#{instance.class.to_s.underscore}_#{anaconda_field_name}_details"></div>

<script>
  (function() {
    window.uploader = new AnacondaUploadField({
      element_id: "##{options[:element_id]}",
      base_key: "#{options[:base_key]}",
      allowed_types: #{options[:allowed_file_types].collect{ |i| i.to_s }},
      upload_details_container: "#{options[:form_options][:upload_details_container]}",
      upload_automatically: #{options[:form_options][:auto_upload] ||= false},
      submit_automatically: #{options[:form_options][:auto_submit] ||= false},
      resource: "#{instance.class.to_s.underscore}",
      attribute: "#{options[:as]}"
    });
  }).call(this);
</script>

      END

      output.html_safe
    end

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
            #["starts-with", "$utf8", ""],
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