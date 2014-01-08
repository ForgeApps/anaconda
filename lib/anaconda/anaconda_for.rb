module Anaconda
  module Model

    def self.included(base)
      base.send :extend, ClassMethods
    end

    module ClassMethods
      
      def anaconda_for( anaconda_columns, options = {})
        send :include, InstanceMethods
        
        anaconda_columns = [anaconda_columns] if anaconda_columns.kind_of?(Symbol) || anaconda_columns.kind_of?(String)
        class_attribute :anaconda_columns
        self.anaconda_columns = anaconda_columns.collect{ |c| c.to_sym }
        # Class.anaconda_columns is now an array of symbols
        
        class_attribute :anaconda_options
        self.anaconda_options = options.reverse_merge(
          aws_access_key_id: AWS[:aws_access_key],
          aws_secret_access_key: AWS[:aws_secret_key],
          bucket: AWS[:aws_bucket],
          acl: "public-read",
          max_file_size: 500.megabytes,
          base_key: "#{self.to_s.pluralize.downcase}/#{anaconda_columns.first.to_s.pluralize}/#{(0...32).map{(65+rand(26)).chr}.join.downcase}"
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
            magic_url(checking_column)
          else
            super
          end
        else
          super
        end
      end
      
      private
      def magic_url(column_name)
        if send("#{column_name}_stored_privately")
          aws = Fog::Storage.new({:provider => 'AWS', :aws_access_key_id => AWS[:aws_access_key], :aws_secret_access_key => AWS[:aws_secret_key]})
          aws.get_object_https_url(AWS[:aws_bucket], send("#{column_name}_file_path"), 1.hour.from_now)
        else
          "https://s3.amazonaws.com/#{AWS[:aws_bucket]}/#{send("#{column_name}_file_path")}"
        end
      end
    end
  end
end