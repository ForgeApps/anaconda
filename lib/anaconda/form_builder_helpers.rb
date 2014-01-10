module Anaconda
  module FormBuilderHelpers

    def anaconda_form_fields( anaconda_field_name )
      output = ""

      output += self.hidden_field "#{anaconda_field_name}_filename".to_sym
      output += self.hidden_field "#{anaconda_field_name}_file_path".to_sym
      output += self.hidden_field "#{anaconda_field_name}_size".to_sym
      output += self.hidden_field "#{anaconda_field_name}_original_filename".to_sym
      output += self.hidden_field "#{anaconda_field_name}_stored_privately".to_sym
      output += self.hidden_field "#{anaconda_field_name}_type".to_sym

      output.html_safe
    end
  end
end