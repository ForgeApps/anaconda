module Anaconda
  module Model

    def self.included(base)
      base.send :extend, ClassMethods
    end

    module ClassMethods

      def anaconda_for( anaconda_column, options = {})
        send :include, InstanceMethods
        
        begin
          self.anaconda_columns.present?
        rescue NoMethodError
          class_attribute :anaconda_columns
        end
        self.anaconda_columns = Array.new unless self.anaconda_columns.kind_of? Array
        if self.anaconda_columns.include? anaconda_column.to_sym
          raise AnacondaError, "anaconda_for cannot be called multiple times for the same field"
        end
        self.anaconda_columns << anaconda_column.to_sym
        # Class.anaconda_columns is now an array of symbols

        class_attribute 
        begin
          self.anaconda_options.present?
        rescue NoMethodError
          class_attribute :anaconda_options
        end
        self.anaconda_options = Hash.new unless self.anaconda_options.kind_of? Hash
        self.anaconda_options[anaconda_column.to_sym] = options.reverse_merge(
          aws_access_key_id: Anaconda.aws[:aws_access_key],
          aws_secret_access_key: Anaconda.aws[:aws_secret_key],
          bucket: Anaconda.aws[:aws_bucket],
          acl: "public-read",
          max_file_size: 500.megabytes,
          allowed_file_types: [],
          base_key: "#{anaconda_column}_anaconda_default_base_key".to_sym,
          host: false,
          protocol: "http",
          expiry_length: 1.hour,
          remove_previous_s3_files_on_change: true,
          remove_previous_s3_files_on_destroy: true
        )
        
        self.after_commit :anaconda_remove_previous_s3_files_on_change_or_destroy
      end
      
      def anaconda_fields_for( anaconda_column )
        if self.anaconda_columns.include? anaconda_column.to_sym
          Anaconda::FieldSuffixes.collect do |suffix|
            "#{anaconda_column}_#{suffix}".to_sym
          end
        else
          raise "#{anaconda_column} not configured for anaconda. Misspelling or did you forget to add the anaconda_for call for this field?"
        end
      end
      
      def anaconda_fields_for_all_columns
        self.anaconda_columns.collect do |column|
          anaconda_fields_for column
        end.flatten
      end
      
    end
    module InstanceMethods
      def method_missing(method, *args, &block)
        checking_column = checking_method = nil
        if self.class.anaconda_columns.present? && self.class.anaconda_columns.any? do |column|
            checking_column = column
            Anaconda::MagicMethods.any? do |magic_method|
              checking_method = magic_method
              "#{column.to_s}_#{magic_method.to_s}" == method.to_s
            end
          end
          case checking_method
          when :url
            anaconda_url(checking_column, *args)
          when :download_url
            anaconda_download_url(checking_column)
          when :anaconda_default_base_key
            anaconda_default_base_key_for(checking_column)
          else
            super
          end
        else
          super
        end
      end

      def anaconda_form_data_for_all_columns
        form_data = {}
        self.anaconda_columns.each do |column|
          form_data[column.to_sym] = anaconda_form_data_for column
        end
        form_data
      end

      def anaconda_form_data_for( anaconda_column )
        if self.anaconda_columns.include? anaconda_column.to_sym
          
          options = self.class.anaconda_options[anaconda_column.to_sym].dup
          
          options[:base_key] = self.send(options[:base_key].to_s) if options[:base_key].kind_of? Symbol
          uploader  = Anaconda::S3Uploader.new(options)
          fields = uploader.fields
          fields[:post_url] = uploader.url
          fields
        else
          raise "#{anaconda_column} not configured for anaconda. Misspelling or did you forget to add the anaconda_for call for this field?"
        end
      end

      private
      def anaconda_url(column_name, *args)
        return nil unless send("#{column_name}_file_path").present?
        options = args.extract_options!
        logger.debug "Extracted Options:"
        logger.debug(options)
        
        if send("#{column_name}_stored_privately")
          aws = Fog::Storage.new({:provider => 'AWS', :aws_access_key_id => Anaconda.aws[:aws_access_key], :aws_secret_access_key => Anaconda.aws[:aws_secret_key], :path_style => Anaconda.aws[:path_style]})
          aws.get_object_https_url(Anaconda.aws[:aws_bucket], send("#{column_name}_file_path"), anaconda_expiry_length(column_name, options[:expires]))
        elsif self.anaconda_options[column_name.to_sym][:host]
          "#{anaconda_protocol(column_name, options[:protocol])}#{self.anaconda_options[column_name.to_sym][:host]}/#{send("#{column_name}_file_path")}"
        else
          "#{anaconda_protocol(column_name, options[:protocol])}#{Anaconda.aws[:aws_endpoint]}/#{send("#{column_name}_file_path")}"
        end
      end
      
      def anaconda_download_url(column_name)
        return nil unless send("#{column_name}_file_path").present?
        options = args.extract_options!
        logger.debug "Extracted Options:"
        logger.debug(options)
        
        aws_options = {query: {"response-content-disposition" => "attachment;"}}
        aws = Fog::Storage.new({:provider => 'AWS', :aws_access_key_id => Anaconda.aws[:aws_access_key], :aws_secret_access_key => Anaconda.aws[:aws_secret_key], :path_style => Anaconda.aws[:path_style]})
        aws.get_object_https_url(Anaconda.aws[:aws_bucket], send("#{column_name}_file_path"), anaconda_expiry_length(column_name, options[:expires]), aws_options)

      end
      
      def anaconda_protocol(column_name, override = nil)
        return override if override
        case self.anaconda_options[column_name.to_sym][:protocol]
        when :auto
          "//"
        else
          "#{self.anaconda_options[column_name.to_sym][:protocol]}://"
        end
      end
      
      def anaconda_expiry_length(column_name, override = nil)
        return override if override
        self.anaconda_options[column_name.to_sym][:expiry_length].seconds.from_now
      end
      
      def anaconda_default_base_key_for(column_name)
        "#{self.class.to_s.pluralize.downcase}/#{column_name.to_s.pluralize}/#{(0...32).map{(65+rand(26)).chr}.join.downcase}"
      end
      
      def anaconda_remove_previous_s3_files_on_change_or_destroy
        
        if self.destroyed?
          self.class.anaconda_columns.each do |column_name|
            next unless self.anaconda_options[column_name.to_sym][:remove_previous_s3_files_on_destroy]
            if self.send("#{column_name}_file_path").present?
              Anaconda.remove_s3_object_in_bucket_with_file_path(Anaconda.aws[:aws_bucket], self.send("#{column_name}_file_path"))
            end
          end
        else
          self.class.anaconda_columns.each do |column_name|
            next unless self.anaconda_options[column_name.to_sym][:remove_previous_s3_files_on_change]
            if self.previous_changes["#{column_name}_file_path"].present?
              # Looks like this field was edited.
              if self.previous_changes["#{column_name}_file_path"][0].present? &&
                self.previous_changes["#{column_name}_file_path"][0] != self.previous_changes["#{column_name}_file_path"][1]
                # It's not a new entry ([0] would be nil), and it really did change, wasn't just committed for no reason
                # So let's delete the previous file from S3
                Anaconda.remove_s3_object_in_bucket_with_file_path(Anaconda.aws[:aws_bucket], self.previous_changes["#{column_name}_file_path"][0])
              end
            end
          end
        end
      end
    end
  end
end