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
          base_key: "#{self.to_s.pluralize.downcase}/#{anaconda_column.to_s.pluralize}/#{(0...32).map{(65+rand(26)).chr}.join.downcase}",
          asset_host: false,
          asset_protocol: "http"
        )
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
            anaconda_url(checking_column)
          else
            super
          end
        else
          super
        end
      end

      private
      def anaconda_url(column_name)
        return nil unless send("#{column_name}_file_path").present?

        if send("#{column_name}_stored_privately")
          aws = Fog::Storage.new({:provider => 'AWS', :aws_access_key_id => Anaconda.aws[:aws_access_key], :aws_secret_access_key => Anaconda.aws[:aws_secret_key]})
          aws.get_object_https_url(Anaconda.aws[:aws_bucket], send("#{column_name}_file_path"), 1.hour.from_now)
        elsif self.anaconda_options[column_name.to_sym][:asset_host]
          "#{anaconda_asset_protocol(column_name)}#{self.anaconda_options[column_name.to_sym][:asset_host]}/#{send("#{column_name}_file_path")}"
        else
          "#{anaconda_asset_protocol(column_name)}s3.amazonaws.com/#{Anaconda.aws[:aws_bucket]}/#{send("#{column_name}_file_path")}"
        end
      end
      
      def anaconda_asset_protocol(column_name)
        case self.anaconda_options[column_name.to_sym][:asset_protocol]
        when :auto
          "//"
        else
          "#{self.anaconda_options[column_name.to_sym][:asset_protocol]}://"
        end
      end
    end
  end
end