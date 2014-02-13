# Three possible configurations:
# Upload automatically and submit form when upload is complete
# Done: Upload automatically but do not submit form automatically
# Done: Do not upload until submit is pressed. The upload and submit form when uploading is complete.
class @AnacondaUploadManager
  constructor: (options = {}) ->
    @anaconda_upload_fields = []
    DLog options
    @form = $("##{options.form_id}")
    @upload_automatically = false
    @submit_automatically = false
    @setup_form_submit_handler()
    self = this
    $(document).on "page:fetch", ->
      DLog "page:fetch"
      self.reset()
    
  register_upload_field: (anaconda_upload_field)->
    DLog "Registering Upload Field"
    @anaconda_upload_fields.push anaconda_upload_field
    if anaconda_upload_field.upload_automatically
      # If _any_ of them have an auto upload, we want to know
      @upload_automatically = true
    if anaconda_upload_field.submit_automatically
      # If _any_ of them have auto submit enabled, we will submit automatically
      @submit_automatically = true
      
  setup_form_submit_handler: ->
    DLog( "Setting up submit handler for form #{@form.attr('id')}")
    @form.on( 'submit', { self: this }, this.form_submit_handler )

  form_submit_handler: (e) ->
    self = e.data.self
    return true if self.upload_automatically || self.all_uploads_are_complete()
    e.preventDefault()
    $(this).off( 'submit', self.form_submit_handler )

    for upload_field, i in self.anaconda_upload_fields
      upload_field.upload()
    false
  reset: ->
    for upload_field, i in @anaconda_upload_fields
      upload_field.reset()
    @anaconda_upload_fields = []
  
  all_uploads_are_complete: ->
    all_completed = true
    for upload_field, i in @anaconda_upload_fields
      if upload_field.upload_in_progress || (!upload_field.upload_in_progress && upload_field.file != null)
        all_completed = false
        break
    return all_completed
  
  upload_completed: ->
    all_completed = true
    for upload_field, i in @anaconda_upload_fields
      if upload_field.upload_in_progress
        all_completed = false
        break
    if all_completed
      @all_uploads_completed()
      
  all_uploads_completed: ->
    if !@upload_automatically || @submit_automatically
      @form.submit()
    else
      @enable_submit_button()  
      
  disable_submit_button: ->
    @form.find("input[type='submit']").prop( "disabled", true );
  enable_submit_button: ->
    @form.find("input[type='submit']").prop( "disabled", false );

class @AnacondaUploadField  
  constructor: (options = {}) ->
    @upload_in_progress = false
    @upload_completed = false
    DLog "options:"
    DLog options
    @element_id = options.element_id ? ""
    @allowed_types = options.allowed_types ? []
    DLog @allowed_types
    @resource = options.resource
    @attribute = options.attribute
    if options.upload_details_container != null && options.upload_details_container != ""
      @upload_details_container = $("##{options.upload_details_container}")
    else
      @upload_details_container = $("##{@resource}_#{@attribute}_details")
    @upload_button = $("##{options.upload_button_id}") ? $("#upload")
    @upload_automatically = options.upload_automatically ? false
    @submit_automatically = options.submit_automatically ? false
    @file = null
    @file_data = null
    @media_types = $(@element_id).data('media-types')
    
    
    @base_key = options.base_key ? ""
    @key = options.key ? "#{@base_key}/${filename}"
    
    @register_with_upload_manager()
    
    @setup_fileupload()

  register_with_upload_manager: ->
    if (@closest_form().length == 0 || @closest_form().attr('id') == 'undefined')
      throw "Anaconda Error: form element not found or missing id attribtue."
    if (typeof( window.anacondaUploadManagers ) == "undefined")
      window.anacondaUploadManagers = []
    if (typeof( window.anacondaUploadManagers[@closest_form().attr('id')] ) == "undefined")
      DLog "registering new upload manager for form #{@closest_form().attr('id')}"
      window.anacondaUploadManagers[@closest_form().attr('id')] = new AnacondaUploadManager({form_id: @closest_form().attr('id')})
    @upload_manager().register_upload_field(this)  
  upload_manager: ->
    window.anacondaUploadManagers[@closest_form().attr('id')]
  closest_form: ->
    $(@element_id).closest("form")
  
  setup_fileupload: ->
    self = this
    $( @element_id ).fileupload
      #dropZone: $("#dropzone")
      add: (e, data) ->
        DLog data
        self.file_selected data
      progress: (e, data) ->
        DLog data
        progress = parseInt(data.loaded / data.total * 100, 10)
        DLog( "Progress for #{self.file.name}: " + progress )
        self.update_progress_to(progress)

      done: (e, data) ->
        self.file_completed_upload data

      fail: (e, data) ->
        alert("#{data.files[0].name} failed to upload.")
        DLog("Upload failed:")
        DLog("Error:")
        DLog(e)
        DLog("data:")
        DLog(data)
        DLog("data.errorThrown:")
        DLog(data.errorThrown )
        DLog("data.textStatus:")
        DLog(data.textStatus )
        DLog("data.jqXHR:")
        DLog(data.jqXHR )

    $(document).bind 'drop dragover', (e) ->
      e.preventDefault()

  upload: ->
    return if @upload_completed
    if @file != null && @file_data != null
      $("input#key").val @key
      @file_data.submit()
      @upload_in_progress = true
      @upload_manager().uploads_started = true
      @upload_manager().disable_submit_button()
      @hide_file_field()

  hide_file_field: ->
    $(@element_id).hide()
  
  is_allowed_type: (file_obj) ->
    
    if 0 == @allowed_types.length || 0 <= @allowed_types.indexOf @get_media_type(file_obj)
      return true
    return false
  
  get_media_type: (file_obj) ->
    media_type = "unknown"
    DLog "get_media_type"
    for k,v of @media_types
      regexp = new RegExp(v, "i")
      if regexp.test(file_obj.type) || regexp.test(file_obj.name)
        media_type = k
    return media_type
    
  reset: ->
    @upload_details_container.html ''

  file_selected: (data) ->
    DLog data
    if @is_allowed_type(data.files[0])
      @file = data.files[0]
      @file_data = data
      DLog @file
      @upload_details_container.html "<div id='upload_file_#{@get_id()}' class='upload-file #{@get_media_type(@file)}'><span class='file-name'>#{@file.name}</span><span class='size'>#{@readable_size()}</span><span class='progress-percent'></span><div class='progress'><span class='progress-bar'></span></div></div>"

      if @upload_automatically
        DLog "auto upload"
        @upload()
      else
        DLog "Not auto upload"
    else
      alert "#{data.files[0].name} is a #{@get_media_type(data.files[0])} file. Only #{@allowed_types.join(", ")} files are allowed."
  get_id: ->
    hex_md5( "#{@file.name} #{@file.size}" )
  
  readable_size: ->
    i = -1;
    byteUnits = [' kB', ' MB', ' GB', ' TB', 'PB', 'EB', 'ZB', 'YB'];
    fileSizeInBytes = @file.size
    loop
      fileSizeInBytes = fileSizeInBytes / 1024
      i++
      break unless fileSizeInBytes > 1024

    Math.max(fileSizeInBytes, 0.1).toFixed(1) + byteUnits[i];
  
  update_progress_to: (progress) ->
    @upload_details_container.find(".progress-percent").html progress + '%'
    @upload_details_container.find('.progress-bar').css('width', progress + '%')
  
  file_completed_upload: (data) ->
    DLog "#{@file.name} completed uploading"
    DLog @file

    # if @upload_complete_post_url? && @upload_complete_post_url != ""
    #   DLog "will now post to #{@upload_complete_post_url}"
    #
    #   file_data = {}
    #   file_data[@resource] = {}
    #   file_data[@resource]["#{@attribute}_file_path"] = "#{@base_key}/#{upload_file.file.name}"
    #   file_data[@resource]["#{@attribute}_filename"] = upload_file.file.name
    #   file_data[@resource]["#{@attribute}_size"] = upload_file.file.size
    #   file_data[@resource]["#{@attribute}_type"] = upload_file.file.media_type
    #   upload_file = this
    #   $.ajax({
    #     type: 'PATCH',
    #     url: @upload_complete_post_url,
    #     data: $.param(file_data)
    #     success: (data, textStatus, jqXHR) ->
    #       DLog "file completed handler complete"
    #       DLog data
    #     #TODO: handle a failure on this POST
    #   })

    # DLog "will now fill form #{@upload_complete_form_to_fill}"

    DLog "#{@resource}_#{@attribute}_file_path"
    hyphenated_resource  = @resource.replace("_", "-")
    hyphenated_attribute = @attribute.replace("_", "-")
    
    $( @element_id ).siblings( "input[data-#{hyphenated_resource}-#{hyphenated_attribute}-file-path]" ).val( @key.replace("${filename}", @file.name) )
    $( @element_id ).siblings( "input[data#{hyphenated_resource}-#{hyphenated_attribute}-filename]" ).val( @file.name )
    $( @element_id ).siblings( "input[data#{hyphenated_resource}-#{hyphenated_attribute}-size]" ).val( @file.size )
    $( @element_id ).siblings( "input[data#{hyphenated_resource}-#{hyphenated_attribute}-type]" ).val( @file.type )

    @upload_in_progress = false;
    @upload_completed = true;
    @upload_manager().upload_completed()


# class @AnacondaUploadFile
# 
#   constructor: (@data) ->
#     @file = @data.files[0]
#     @media_type = @get_media_type()
#     @id = @get_id()
# 
#     @set_context()
#   get_media_type: ->
#     media_type = "unknown"
#     return media_type
#   set_context: ->
#     @data.context = this
#   submit: ->
#     @data.submit()
#   update_progress_to: (progress) ->
#     $("#upload_file_#{@id} .progress-percent").html progress
#     $("#upload_file_#{@id}").find('.progress-bar').css('width', progress + '%')