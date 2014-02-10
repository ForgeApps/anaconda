# anaconda

Dead simple direct-to-s3 file uploading for your rails app.

## Alpha Warning

We intend to follow semantic versioning as of 1.0. Before that time breaking changes may occur, as development is very active.

If you require stability before that time, you are strongly encouraged to specify an exact version in your `Gemfile` to avoid updating to a version that breaks things for you.

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

*  Fields
	
	At this point you will have these methods available on a post_media instance:
  	* :asset_filename
  	* :asset_file_path
  	* :asset_size
    * :asset_original_filename
    * :asset_stored_privately
    * :asset_type
    * :asset_url
    
    The magic method is asset_url which will return a signed S3 URL if the file is stored with an ACL of `private` and will return a non-signed URL if the file is stored with public access.

## Changelog
* 0.9.7
  * Add percent sign to progress-percent div
* 0.9.6
  * Fix `auto_upload` and `auto_submit` options.
  
* 0.9.5
  * add `host` and `protocol` options to `anaconda_for`

* 0.9.4
	* 	Fix uploads. Previous version broke them completely.
	
* 0.9.3
	* If no files have been selected, let form submit as normal

* 0.9.2
  * Always use UTC for policy expiration date, even if Time.zone is set to something else.

* 0.9.1
  
  * Fix for anaconda:migration when the field name has an underscore in it

* 0.9.0

  * Add support for multiple anaconda uploaders per form
  
  * Completely refactor JavaScript file to support multiple uploaders
  
  * Add auto_submit option
  
  * Fix support for allowed_types
  
  * Add file_types to anaconda config
  
  * Add fix for sites using Turbolinks

* 0.2.0
	
	* Add support for multiple `anaconda_for` calls per model. Currently limited to one per form, however.

	* Improve migration generation file and class naming to include field name

	* `post_media.asset_url` will now return nil if the file_path is nil
  
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