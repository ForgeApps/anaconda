module Anaconda
  module FormBuilderHelpers

    def anaconda( anaconda_field_name, form_options = {} )
      output = ""
      instance = nil
      options = {}

      element_id = "anaconda_file_#{anaconda_field_name}_#{rand(999999999)}"
      output += "<div class='anaconda_dropzone'>"
      
      if defined?(SimpleForm) && defined?(SimpleForm::FormBuilder) && self.class == SimpleForm::FormBuilder
        instance = self.object
        a_class = self.object.class unless self.object.kind_of? Class

        begin
          options = a_class.anaconda_options[anaconda_field_name.to_sym].dup
        rescue
          raise AnacondaError, "attribute options not set for column #{anaconda_field_name}. Did you add `anaconda_for :#{anaconda_field_name}` to the model?"
        end
        if form_options[:base_key]
          options[:base_key] = form_options[:base_key]
        else
          options[:base_key] = instance.send(options[:base_key].to_s) if options[:base_key].kind_of? Symbol
        end
        
        uploader = Anaconda::S3Uploader.new(options)
        output += self.input_field "file", name: "file", id: element_id, as: :file, data: {url: uploader.url, form_data: uploader.fields.to_json, media_types: Anaconda.js_file_types}
      elsif self.class == ActionView::Helpers::FormBuilder
        instance = self.object
        a_class = self.object.class unless self.object.kind_of? Class

        begin
          options = a_class.anaconda_options[anaconda_field_name.to_sym].dup
        rescue
          raise AnacondaError, "attribute options not set for column #{anaconda_field_name}. Did you add `anaconda_for :#{anaconda_field_name}` to the model?"
        end
        
        if options.nil?
          raise AnacondaError, "attribute options not set for column #{anaconda_field_name}. Did you add `anaconda_for :#{anaconda_field_name}` to the model?"
        end        
        
        ::Rails.logger.info "form_options: #{form_options}"
        ::Rails.logger.info "options: #{options}"
        
        if form_options[:base_key]
          options[:base_key] = form_options[:base_key]
        else
          options[:base_key] = instance.send(options[:base_key].to_s) if options[:base_key].kind_of? Symbol
        end
        
        uploader = Anaconda::S3Uploader.new(options)
        output += self.file_field "file", name: "file", id: element_id, data: {url: uploader.url, form_data: uploader.fields.to_json, media_types: Anaconda.js_file_types}
      end

      output += self.hidden_field "#{anaconda_field_name}_filename".to_sym, data: {"#{instance.class.to_s.underscore}_#{anaconda_field_name}_filename" => true}
      output += self.hidden_field "#{anaconda_field_name}_file_path".to_sym, data: {"#{instance.class.to_s.underscore}_#{anaconda_field_name}_file_path" => true}
      output += self.hidden_field "#{anaconda_field_name}_size".to_sym, data: {"#{instance.class.to_s.underscore}_#{anaconda_field_name}_size" => true}
      output += self.hidden_field "#{anaconda_field_name}_original_filename".to_sym, data: {"#{instance.class.to_s.underscore}_#{anaconda_field_name}_original_filename" => true}
      output += self.hidden_field "#{anaconda_field_name}_stored_privately".to_sym, data: {"#{instance.class.to_s.underscore}_#{anaconda_field_name}_stored_privately" => true}
      output += self.hidden_field "#{anaconda_field_name}_type".to_sym, data: {"#{instance.class.to_s.underscore}_#{anaconda_field_name}_type" => true}
      # output += render(:template =>"anaconda/_uploader_form_for.html.haml", :locals => {resource: instance, options: options.merge(as: anaconda_field_name, form_options: form_options, element_id: element_id )}, layout: false).to_s
      
      if form_options[:remove_button] && self.object.send("#{anaconda_field_name}_file_path").present?
        remove_button_text = form_options[:remove_button].kind_of?(String) ? form_options[:remove_button] : "Remove"
        output += "<a href='#' data-#{"remove_#{instance.class.to_s.underscore}_#{anaconda_field_name}".gsub('_', '-')}>#{remove_button_text}</a>"
      end
      
      output += "</div>" #anaconda_dropzone

      options = options.merge(as: anaconda_field_name, form_options: form_options, element_id: element_id )
      
      output += <<-END
<div id="#{instance.class.to_s.underscore}_#{anaconda_field_name}_details"></div>
<script>
  (function() {
    new AnacondaUploadField({
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
  end
end