* 0.14.0
  * Add ability to specify protocol in the magic `asset_url` method

* 0.13.1
  * Use UTC for timestamp in migration files.
  
* 0.13.0
  * Set Content-Type for S3 file to match that of the uploaded source file.
  
* 0.12.2
  * Fix bug introduced in 0.12.1
  * Wrap hidden fields in the anaconda_dropzone div (to fix bug)
  
* 0.12.1
  * Make progress bar go to 100% on upload complete
  * Properly store ACL on file upload (`asset_stored_privately`)
  * Properly store `original_filename` on upload
  * Fix bug when dragging and dropping onto the file select button

* 0.12.0
  * Delete files from S3 when a new one us uploaded, or the record is deleted.
  * Add options to disable deleting files from S3 when a new one is uploaded (`remove_previous_s3_files_on_change` and `remove_previous_s3_files_on_destroy`). These default to `true`
  * Add `Model.anaconda_fields_for_all_columns` and `Model.anaconda_fields_for(column_name)` methods to make strong parameters cleaner
  
* 0.11.0
  * Change aws URLs to use path style URLs
  
* 0.10.0
  * Add `download_url` magic method that uses content-disposition to force the browser to download the URL. This is a signed AWS url that is only valid for 1 hour

* 0.9.10
  * Fix bug when attribute had more than one underscore
  
* 0.9.9
  * Fix bug untroduced in previous version
* 0.9.8
  * Add `base_key` option
  * Change the way we identify hidden elements to work when we're using this in a nested form.
  
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