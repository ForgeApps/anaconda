= anaconda

Description goes here.

== Contributing to anaconda
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
* Fork the project.
* Start a feature/bugfix branch.
* Commit and push until you are happy with your contribution.
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

== Copyright

Copyright (c) 2014 Ben McFadden. See LICENSE.txt for
further details.




Columns we're expecting (in the case of `anaconda_for :image`)
image_file_path
image_size
image_original_filename

Magic Columns we'll make
image_url


You'll have to make and run a migration for the columns you want:
`rails g migration AddAnacondaToUsers image_file_path:text image_size:integer image_original_filename:text`