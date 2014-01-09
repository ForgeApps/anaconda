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

### AWS S3 Setup

#### IAM

Sample IAM Policy (be sure to replace 'your.bucketname'):

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

Sample CORS configuration:

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

*  Controller changes (if any)

*  Migrations

        $ rails g migration anaconda:migration PostMedia asset

*  Model setup

        class PostMedia < ActiveRecord::Base
          belongs_to :post

          anaconda_for :asset, base_key: :asset_key

          def asset_key
			  o = [('a'..'z'), ('A'..'Z')].map { |i| i.to_a }.flatten
			  s = (0...24).map { o[rand(o.length)] }.join
			  "post_media/#{s}"
			end



*  Form setup

        #anaconda_upload_form_wrapper
        = anaconda_uploader_form_for post_media, :asset, form_el: '#new_post_media', limits: { images: 9999 }, auto_upload: true


*  Options

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




Columns we're expecting (in the case of `anaconda_for :image`)
image_file_path
image_size
image_original_filename

Magic Columns we'll make
image_url


You'll have to make and run a migration for the columns you want:
`rails g migration AddAnacondaToUsers image_file_path:text image_size:integer image_original_filename:text`