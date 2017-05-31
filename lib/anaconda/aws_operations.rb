require 'aws-sdk'

module Anaconda
  module AWSOperations
    def self.public_url( key: "", options: {} )
      aws_options = {query: {"response-content-disposition" => "attachment;#{options[:filename]}"}}
      
      s3 = Aws::S3::Client.new( { region: options[:aws_region], credentials: Aws::Credentials.new( options[:aws_access_key], options[:aws_secret_key] ) } )
      bucket = Aws::S3::Bucket.new( name: options[:aws_bucket], client: s3 )
      
      if options[:expires].present?
        bucket.object(key).presigned_url( :get, expires_in: options[:expires], acl: 'public-read', query: {"response-content-disposition" => "attachment;#{options[:filename]}"} )
      else
        bucket.object(key).public_url( query: {"response-content-disposition" => "attachment;#{options[:filename]}"} )
      end
        
      # aws.get_object_https_url(options[:aws_bucket], send("#{column_name}_file_path"), anaconda_expiry_length(column_name, options[:expires]), aws_options)
    end
    
    def self.put_s3_object( key: "", data: nil, options: {} )
      s3 = Aws::S3::Client.new( { region: options[:aws_region], credentials: Aws::Credentials.new( options[:aws_access_key], options[:aws_secret_key] ) } )
      bucket = Aws::S3::Bucket.new( name: options[:aws_bucket], client: s3 )
      obj = bucket.put_object({ key: key, body: data, acl: options[:acl] } )
    end
    
    def self.remove_s3_object( key: "", options: {} )
      
      puts "remove_s3_object"
      puts "options: #{options}"
      
      s3 = Aws::S3::Client.new( { region: options[:aws_region], credentials: Aws::Credentials.new( options[:aws_access_key], options[:aws_secret_key] ) } )
      bucket = Aws::S3::Bucket.new( name: options[:aws_bucket], client: s3 )
      obj = bucket.object(key)
      obj.delete      
    end
  end
end