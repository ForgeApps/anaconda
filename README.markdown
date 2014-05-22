# Anaconda

Dead simple direct-to-s3 file uploading for your rails app.

Current Version: 1.0.4

## Installation

1.  Add to your `Gemfile`

        gem 'anaconda'

2.  `bundle install`

3.  Add the following to your `application.js`

        //= require anaconda

4.  Finally, run the installer to install the configuration initializer into `config/initializers/anaconda.rb`

        $ rails g anaconda:install

## Configuration

### AWS S3 Setup
Create a bucket where you want your uploads to go. If you already have a bucket in place, you can certainly use it.

#### IAM
For best security we recommend creating a user in IAM that will just be used for file uploading. Once you create that user you can apply a security policy to it so they can only access the specified resources. Here is an example IAM policy that will restrict this user to only have access to the one bucket specified (be sure to replace 'your.bucketname'). Be sure to generate security credentials for this user. These are the S3 credentials you will use.

    {
      "Statement": [
            {
              "Effect": "Allow",
              "Action": "s3:*",
              "Resource": [
                  "arn:aws:s3:::[your.bucketname]",
                  "arn:aws:s3:::[your.bucketname]/*"
                ]
            }
        ]
    }

#### CORS
You will need to set up CORS permissions on the bucket so users can upload to it from your website. Below is a sample CORS configuration.

If users will only upload from one domain, you can put that in your AllowedOrigin. If they will upload from multiple domains you may either add an AllowedOrigin for each of them, or use a wildcard `*` origin as in our example below.

    <?xml version="1.0" encoding="UTF-8"?>
      <CORSConfiguration xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
      <CORSRule>
        <AllowedOrigin>*</AllowedOrigin>
        <AllowedMethod>GET</AllowedMethod>
        <AllowedMethod>POST</AllowedMethod>
        <AllowedMethod>PUT</AllowedMethod>
        <MaxAgeSeconds>3000</MaxAgeSeconds>
        <AllowedHeader>*</AllowedHeader>
      </CORSRule>
    </CORSConfiguration>


### Initializer

The initializer installed into `config/initializers/anaconda.rb` contains the settings you need to get anaconda working.

**You must set these to your S3 credentials/settings in order for anaconda to work.**

We highly recommend the `figaro` gem [https://github.com/laserlemon/figaro](https://github.com/laserlemon/figaro) to manage your environment variables in development and production.

## Usage

*  Controller changes
  	
  	You must add these parameters to your permitted parameters. In Rails 4 this is done via strong parameters in the controller. In Rails 3 this is done in the model via attr_accessible.
  	
  	We add two Class methods on the model that return an array of columns used by each anaconda_for column. One is scoped per anaconda field, and the other returns all of the columns anaconda needs for the entire model. This is useful if you have multiple anaconda columns in your model.
  	
  	You can use these methods in your strong parameter list directly. Ex:
  	
  		PostMediasController < Application Controller
  		...
	  		def post_media_params
	  			params.require(:post_media).permit(
	  			:name,
	  			:foobar,
	  			PostMedia.anaconda_fields_for( :asset )
	  			)
	  		end
  		end
  	
  	This keeps your strong parameter list clean and dry. If you have multiple anaconda models in your model and you wish for all of the params for all of the models to be permitted, you may use `PostMedia.anaconda_fields_for_all_columns` instead.
  	
  	We have not tested if you can use `Model.anaconda_fields_for( column )` in the rails 3 attr_accessible list.
  	
  	If you prefer to do this manually the fields this permit are listed below.

  	For each `anaconda_for` (assuming `anaconda_for :asset`):
  	
  	* :asset_filename
  	* :asset_file_path
  	* :asset_size
    * :asset_original_filename
    * :asset_stored_privately
    * :asset_type


*  Migrations
	
	We provide a migration generator. Assuming `anaconda_for :asset` inside of PostMedia model:

        $ rails g anaconda:migration PostMedia asset

*  Model setup
	
		class PostMedia < ActiveRecord::Base
		  belongs_to :post
			
		  anaconda_for :asset, base_key: :asset_key
			
		  def asset_key
			o = [('a'..'z'), ('A'..'Z')].map { |i| i.to_a }.flatten
			s = (0...24).map { o[rand(o.length)] }.join
			"post_media/#{s}"
		  end
		end
	
	At this time the available options on anaconda_for are:
	* `base_key` default: _%{plural model}/%{plural column}/%{random string}_
	* `aws_access_key_id` default: _aws_access_key_ specified in Anaconda config
	* `aws_secret_access_key` default: _aws_secret_key_ specified in Anaconda config
	* `bucket` default: _aws_bucket_ specified in Anaconda config
	* `acl` default _public-read_
	* `max_file_size` default: `500.megabytes`
	* `allowed_file_types` default: _all_
	* `host` String. If specified, this will be used to access publically stored objects instead of the S3 bucket. Useful for CloudFront integration. Note: At this time privately stored objects will still be requested via S3. Default: _false_
	* `protocol` `https`, `http`, or `:auto`. If `:auto`, `//` will be used as the protocol. Note: At this time, all privately stored objects are requested over https. Default: `http`
  * `remove_previous_s3_files_on_change` Boolean. If true, files will be removed from S3 when a new file is uploaded. Default: `true`
  * `remove_previous_s3_files_on_destroy` Boolean. If true, files will be removed from S3 when a record is destroyed. Default: `true`

*  Form setup

	At this time we only support anaconda fields inside of a [simple_form](https://github.com/plataformatec/simple_form). We plan to expand and add a rails form helper in the future.
	
		= simple_form_for post_media do |f|
			= f.anaconda :asset
			= f.name
			= f.other_field
			= f.submit
			
	**Form helper options**
	
	There are a variety of options available on the form helper. At this time they are:
	
	* `upload_details_container` - An element id you would like the upload details located in. Defaults to `<resource>_<attribtue>_details`  ex: `post_media_asset_details`
	* `auto_upload` - If set to true, upload will begin as soon as a file is selected. Default: *false*
	* `auto_submit` - If set to true, form will submit automatically when upload is completed. Useful when mixed with `auto_upload: true`, especially if the file field is the only field on the form. Default: *true* when auto_upload is false; *false* when auto_upload is true.
  * `base_key` - If supplied, this will be the base_key used for this upload

*  Fields
	
	At this point you will have these methods available on a post_media instance:
  	* :asset_filename
  	* :asset_file_path
  	* :asset_size
    * :asset_original_filename
    * :asset_stored_privately
    * :asset_type
    * :asset_url
    * :asset_download_url
    
    The magic methods are asset_url and asset_download_url.
    
    `asset_url` will return a signed S3 URL if the file is stored with an ACL of `private` and will return a non-signed URL if the file is stored with public access.
    
    You may pass an options hash to the `asset_url` magic method. At this time, the only supported option is :protocol. Example: `asset_url({protocol: 'http'})`  This will override the `protocol` option set in the model.
    
    `asset_download_url` will return a signed S3 URL with content-disposition set to attachment so the file will be downloaded instead of opened in the browser.

### Advanced Usage

#### Events
There are several events fired throughout the upload process that you can subscribe to. Many of them contain useful data along with the event. The documentation needs expanding here.

* `anaconda:manager:upload-manager-constructor` fired when the first upload element constructs an upload manager for a form
* `anaconda:manager:upload-field-registered` fired when an upload field registers itself with an upload manager
* `anaconda:manager:uploads-starting` fired when the form is submitted and Anaconda starts uploading the selected files
* `anaconda:manager:upload-completed` fired each time an upload is completed
* `anaconda:manager:all-uploads-completed` fired once all uploads have completed
* `anaconda:file-selected` fired when a file is selected
* `anaconda:file-upload-failed` fired when an upload fails
* `anaconda:file-upload-started` fired for each upload when it is started
* `anaconda:invalid-file-type-selected` fired when a non-permitted file type is selected
* `anaconda:file-upload-completed` fired when an upload is completed

If you return false to the following events it will prevent the default behavior:

* `anaconda:invalid-file-type-selected` Default behavior is an alert with content `_filename_ is a _filetype_ file. Only _allowed file types_ files are allowed.`
* `anaconda:file-upload-failed` Default behavior is an alert with content `_filename_ failed to upload.`


## Versioning
From version 1.0.0 on we have used [Semantic Versioning](http://semver.org/).

## Changelog
* 1.0.4
  * Add `anaconda_form_data_for()` and `anaconda_form_data_for_all_columns` instance methods that return the raw data needed to upload to AWS
  
* 1.0.3
  * Properly define dependencies so they are included
  * Add support for non US Standard region buckets. See new `aws_endpoint` option in the config

* 1.0.2
  * Refactor S3Uploader into it's own class so it can be used outside of the form helper
  
* 1.0.1 
  * Use OpenSSL::Digest instead of deprecated OpenSSL::Digest::Digest.
  
* 1.0.0
  * Fix incorrect return value from `all_uploads_are_complete` method in AnacondaUploadManager
  * Remove unused `upload_helper.rb` and other old code.
  * Add a bunch of JavaScript events

See [changelog](CHANGELOG.md) for previous changes
  
## Contributing to anaconda

* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
* Fork the project.
* Start a feature/bugfix branch.
* Commit and push until you are happy with your contribution.
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (c) 2014 Forge Apps, LLC. See LICENSE.txt for
further details.