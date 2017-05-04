require 'spec_helper'
require 'open-uri' 

describe Anaconda do

  before(:all) do
    @aws_credentials = { access_key:  ENV["AWS_ACCESS_KEY"], 
                         secret_key:  ENV["AWS_SECRET_KEY"],
                         bucket_name: ENV["AWS_BUCKET"],    
                         region:      ENV["AWS_ENDPOINT"]  }
  end

  context "Uploading files" do
    
    it "Should be able to upload a file and get a public URL for it and then delete it" do
      @random_filename = (0...50).map { ('a'..'z').to_a[rand(26)] }.join
      
      Anaconda::AWSOperations.put_s3_object( key: @random_filename, data: File.read( File.join( "spec", "test_data", "hello.txt" ) ), options: @aws_credentials.merge( { acl: 'public-read' } ) )
      
      puts "Uploaded #{@random_filename}"
      
      public_url = Anaconda::AWSOperations.public_url( key: @random_filename, options: @aws_credentials )
      
      content = open( public_url ).read
      
      expect( content.size ).to be > 0
      
      puts "Public URL: #{public_url}"
      
      Anaconda::AWSOperations.remove_s3_object( key: @random_filename, options: @aws_credentials )
      
      expect{ content = open( public_url ).read }.to raise_error(OpenURI::HTTPError)
    end
    
  end
end