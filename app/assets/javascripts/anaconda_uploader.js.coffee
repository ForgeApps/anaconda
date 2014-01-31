class @AnacondaUploadManager
  @deubg_enabled: false
  @uploads_started: false

  constructor: (options = {}) ->
    @form_fields = []
  register_upload_field: ->
    DLog "Registering Upload Field"
  

class @AnacondaUploadField
  @debug_enabled: false
  @upload_started: false

  constructor: (options = {}) ->
    @element_id = options.element_id ? ""
    @allowed_types = options.allowed_types ? []
    @upload_details_container = $("##{options.upload_details_container}") ? $("#files")
    @upload_button = $("##{options.upload_button_id}") ? $("#upload")
    @upload_complete_post_url = options.upload_complete_post_url ? null
    @upload_complete_form_to_fill = options.upload_complete_form_to_fill ? null
    @upload_automatically = options.upload_automatically ? false
    @resource = options.resource ? null
    @attribute = options.attribute ? null

    @files_for_upload = []
    @base_key = options.base_key ? ""
    
    @register_with_upload_manager()
    
    @setup_fileupload()

  register_with_upload_manager: ->
    if (@closest_form().length == 0 || @closest_form().attr('id') == 'undefined')
      throw "Anaconda Error: form element not found or missing id attribtue."
    if (typeof( window.anacondaUploadManagers ) == "undefined")
      window.anacondaUploadManagers = []
    if (typeof( window.anacondaUploadManagers[@closest_form().attr('id')] ) == "undefined")
      window.anacondaUploadManagers[@closest_form().attr('id')] = new AnacondaUploadManager()
    @upload_manager().register_upload_field(this)  
  upload_manager: ->
    window.anacondaUploadManagers[@closest_form().attr('id')]
  closest_form: ->
    $(@element_id).closest("form")
  setup_fileupload: ->
    self = this
    $( @element_id ).fileupload
      dropZone: $("#dropzone")
      add: (e, data) ->
        self.add_file data
      progress: (e, data) ->
        DLog data
        progress = parseInt(data.loaded / data.total * 100, 10)
        DLog( "Progress: " + progress )
        data.context.update_progress_to(progress)

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

  setup_upload_button_handler: ->
    #alert( "setup_upload_button_handler for #{@element_id}" )
    unless ( @upload_automatically == true )
      DLog( "Setting up submit handler for element #{@element_id}")
      $(@element_id).closest( 'form' ).on( 'submit', { self: this }, this.form_submit_handler )

  form_submit_handler: (e) ->
    # alert( 'form_submit_handler' )
    e.preventDefault()
    self = e.data.self
    $(this).off( 'submit', self.form_submit_handler )

    self.files_for_upload[0].submit()
    false

  files_by_type: (type) ->
    matches = []
    for v,i in @files_for_upload
      if v.media_type == type
        matches.push v
    return matches

  upload_files: ->
    media_type = null
    for v,i in @files_for_upload
      $("input#key").val "#{@base_key}/${filename}"
      v.submit()

  is_allowed_type: (upload_file) ->
    if 0 == @allowed_types.length || 0 <= @allowed_types.indexOf upload_file.media_type
      return true
    return false

  is_within_limits: (upload_file) ->
    if !@limits[upload_file.media_type]? || @limits[upload_file.media_type] > @files_by_type(upload_file.media_type).length
      return true
    return false

  reset: ->
    @files_for_upload = []
    @upload_details_container.html ''

  add_file: (data) ->
    upload_file = new AnacondaUploadFile data
    if @is_allowed_type(upload_file)
      if @is_within_limits(upload_file)
        @files_for_upload.push upload_file
        DLog(upload_file)
        @upload_details_container.append "<div id='upload_file_#{upload_file.id}' class='upload-file #{upload_file.media_type}'><span class='file-name'>#{upload_file.file.name}</span><span class='size'>#{upload_file.file.size}</span><span class='progress-percent'></span><div class='progress'><span class='progress-bar'></span></div></div>"

        if @upload_automatically == true
          DLog( "Upload Automatically: #{@upload_automatically}")
          upload_file.submit()
        else
          @setup_upload_button_handler()
      else
        alert "Only #{@limits[upload_file.media_type]} #{upload_file.media_type} files are allowed"
    else
      alert "#{upload_file.file.name} is a #{upload_file.media_type} file. Only #{@allowed_types.join(", ")} files are allowed."
  file_completed_upload: (data) ->
    upload_file = data.context
    DLog "#{upload_file.file.name} completed uploading"
    DLog upload_file

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

    DLog "will now fill form #{@upload_complete_form_to_fill}"

    DLog "#{@resource}_#{@attribute}_file_path"

    $( @element_id ).siblings( '#' + "#{@resource}_#{@attribute}_file_path" ).val( "#{@base_key}/#{upload_file.file.name}" )
    $( @element_id ).siblings( '#' + "#{@resource}_#{@attribute}_filename" ).val( upload_file.file.name )
    $( @element_id ).siblings( '#' + "#{@resource}_#{@attribute}_size" ).val( upload_file.file.size )
    $( @element_id ).siblings( '#' + "#{@resource}_#{@attribute}_type" ).val( upload_file.file.type )

    $( @element_id ).closest( 'form' ).submit() unless ( @upload_automatically == true )

class @AnacondaUploadFile

  constructor: (@data) ->
    @file = @data.files[0]
    @media_type = @get_media_type()
    @id = @get_id()

    @set_context()
  get_id: ->
    hex_md5( "#{@file.name} #{@file.size}" )
  get_media_type: ->
    if AnacondaUploader.audio_types.test(@file.type) || AnacondaUploader.audio_types.test(@file.name)
      media_type = "audio"
    else if AnacondaUploader.video_types.test(@file.type) || AnacondaUploader.video_types.test(@file.name)
      media_type = "video"
    else if AnacondaUploader.image_types.test(@file.type) || AnacondaUploader.image_types.test(@file.name)
      media_type = "image"
    else if AnacondaUploader.resource_types.test(@file.type) || AnacondaUploader.resource_types.test(@file.name)
      media_type = "resource"
    else
      media_type = "unknown"
    return media_type
  set_context: ->
    @data.context = this
  submit: ->
    @data.submit()
  update_progress_to: (progress) ->
    $("#upload_file_#{@id} .progress-percent").html progress
    $("#upload_file_#{@id}").find('.progress-bar').css('width', progress + '%')