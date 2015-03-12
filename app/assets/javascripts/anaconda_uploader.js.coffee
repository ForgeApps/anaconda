triggerEvent = (name, data) ->
  # Taken directly from Turbolinks with no shame.
  # https://github.com/rails/turbolinks/blob/master/lib/assets/javascripts/turbolinks.js.coffee
  event = document.createEvent 'Events'
  event.data = data if data
  event.initEvent name, true, true
  document.dispatchEvent event

class @AnacondaUploadManager
  constructor: (options = {}) ->
    @anaconda_upload_fields = []
    # DLog options
    @form = $("##{options.form_id}")
    @upload_automatically = false
    @submit_automatically = false
    triggerEvent "anaconda:manager:upload-manager-constructor", { form: @form }
    @setup_form_submit_handler()
    @bind_dropzone_effects()
    self = this
    $(document).on "page:fetch", ->
      # DLog "page:fetch"
      self.reset()
    
  register_upload_field: (anaconda_upload_field)->
    # DLog "Registering Upload Field"
    triggerEvent "anaconda:manager:upload-field-registered", { uploadField: anaconda_upload_field, resource: "#{anaconda_upload_field.hyphenated_resource}-#{anaconda_upload_field.hyphenated_attribute}" }
    @anaconda_upload_fields.push anaconda_upload_field
    if anaconda_upload_field.upload_automatically
      # If _any_ of them have an auto upload, we want to know
      @upload_automatically = true
    if anaconda_upload_field.submit_automatically
      # If _any_ of them have auto submit enabled, we will submit automatically
      @submit_automatically = true
      
  setup_form_submit_handler: ->
    # DLog( "Setting up submit handler for form #{@form.attr('id')}")
    @form.on( 'submit', { self: this }, this.form_submit_handler )

  form_submit_handler: (e) ->
    self = e.data.self
    return true if self.upload_automatically || self.all_uploads_are_complete()
    e.preventDefault()
    triggerEvent "anaconda:manager:uploads-starting", { form: @form }
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
      if upload_field.upload_in_progress || (!upload_field.upload_in_progress && upload_field.file != null && !upload_field.upload_completed)
        all_completed = false
        break
    return all_completed
  
  upload_completed: ->
    triggerEvent "anaconda:manager:upload-completed", { form: @form }
    all_completed = true
    for upload_field, i in @anaconda_upload_fields
      if upload_field.upload_in_progress
        all_completed = false
        break
    if all_completed
      @all_uploads_completed()
      
  all_uploads_completed: ->
    triggerEvent "anaconda:manager:all-uploads-completed", { form: @form }
    if !@upload_automatically || @submit_automatically
      setTimeout =>
        @form.submit()
      , 610
    else
      @enable_submit_button()  
      
  disable_submit_button: ->
    @form.find("input[type='submit']").prop( "disabled", true );
  enable_submit_button: ->
    @form.find("input[type='submit']").prop( "disabled", false );
    
  bind_dropzone_effects: ->
    $(document).bind 'drop dragover', (e) ->
      e.preventDefault()
      
    $(document).bind 'dragover', (e) ->
      dropZone = $('.anaconda_dropzone')
      timeout = window.dropZoneTimeout
      if !timeout
        dropZone.addClass('in');
      else
        clearTimeout(timeout);
        
      found = false
      node = e.target
      
      while node != null
        if node in dropZone
            found = true
            break
          node = node.parentNode;
      
      if found
        dropZone.addClass('hover')
      else
        dropZone.removeClass('hover')

      window.dropZoneTimeout = setTimeout ->
        window.dropZoneTimeout = null
        dropZone.removeClass('in hover')
      , 100    

class @AnacondaUploadField  
  constructor: (options = {}) ->
    @upload_in_progress = false
    @upload_completed = false
    # DLog "options:"
    # DLog options
    @element_id = options.element_id ? ""
    @allowed_types = options.allowed_types ? []
    # DLog @allowed_types
    @resource = options.resource
    @attribute = options.attribute
    @hyphenated_resource  = @resource.replace(/_/g, "-")
    @hyphenated_attribute = @attribute.replace(/_/g, "-")
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
    @acl = $(@element_id).data('form-data').acl
    
    @base_key = options.base_key ? ""
    @key = options.key ? "#{@base_key}/${filename}"
    
    @register_with_upload_manager()
    
    @setup_fileupload()
    @bind_remove_button()

  register_with_upload_manager: ->
    if (@closest_form().length == 0 || @closest_form().attr('id') == 'undefined')
      throw "Anaconda Error: form element not found or missing id attribtue."
    if (typeof( window.anacondaUploadManagers ) == "undefined")
      window.anacondaUploadManagers = []
    if (typeof( window.anacondaUploadManagers[@closest_form().attr('id')] ) == "undefined")
      # DLog "registering new upload manager for form #{@closest_form().attr('id')}"
      window.anacondaUploadManagers[@closest_form().attr('id')] = new AnacondaUploadManager({form_id: @closest_form().attr('id')})
    @upload_manager().register_upload_field(this)  
  upload_manager: ->
    window.anacondaUploadManagers[@closest_form().attr('id')]
  closest_form: ->
    $(@element_id).closest("form")
  
  setup_fileupload: ->
    self = this
    $( @element_id ).fileupload
      dropZone: $( @element_id ).parent(".anaconda_dropzone"),
      add: (e, data) ->
        self.file_selected data
      progress: (e, data) ->
        # DLog data
        progress = parseInt(data.loaded / data.total * 100, 10)
        # DLog( "Progress for #{self.file.name}: " + progress )
        self.update_progress_to(progress)

      done: (e, data) ->
        self.update_progress_to(100)
        self.file_completed_upload data

      fail: (e, data) ->
        alert("#{data.files[0].name} failed to upload.") if triggerEvent "anaconda:file-upload-failed", { data: data, resource: "#{@hyphenated_resource}-#{@hyphenated_attribute}" }
        # DLog("Upload failed:")
        # DLog("Error:")
        # DLog(e)
        # DLog("data:")
        # DLog(data)
        # DLog("data.errorThrown:")
        # DLog(data.errorThrown )
        # DLog("data.textStatus:")
        # DLog(data.textStatus )
        # DLog("data.jqXHR:")
        # DLog(data.jqXHR )
  
  bind_remove_button: ->
    $("a[data-remove-#{@hyphenated_resource}-#{@hyphenated_attribute}]").click (e) =>
      e.preventDefault()
      @remove_file()
  
  upload: ->
    return if @upload_completed
    if @file != null && @file_data != null
      triggerEvent "anaconda:file-upload-started", { file: @file, resource: "#{@hyphenated_resource}-#{@hyphenated_attribute}" }
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
    # DLog "get_media_type"
    for k,v of @media_types
      regexp = new RegExp(v, "i")
      if regexp.test(file_obj.type) || regexp.test(file_obj.name)
        media_type = k
    return media_type
    
  reset: ->
    @upload_details_container.html ''
    
  stored_privately: ->
    if @acl == "private"
      true
    else
      false

  file_selected: (data) ->
    # DLog "file_selected"
    # DLog data
    if @is_allowed_type(data.files[0])
      @file = data.files[0]
      @file_data = data
      @set_content_type()
      
      triggerEvent "anaconda:valid-file-selected", { file: data.files[0], resource: "#{@hyphenated_resource}-#{@hyphenated_attribute}" }
      
      # This remove button is for removing an already uploaded file,
      # not removing the just selected file. Let's not confuse people.
      $("a[data-remove-#{@hyphenated_resource}-#{@hyphenated_attribute}]").hide()
      
      
      # DLog @file
      @upload_details_container.html "<div id='upload_file_#{@get_id()}' class='upload-file #{@get_media_type(@file)}'><span class='file-name'>#{@file.name}</span><span class='size'>#{@readable_size()}</span><span class='progress-percent'></span><div class='progress'><span class='progress-bar'></span></div></div>"

      if @upload_automatically
        # DLog "auto upload"
        @upload()
      else
        # DLog "Not auto upload"
    else
      if triggerEvent "anaconda:invalid-file-selected", { file: data.files[0], resource: "#{@hyphenated_resource}-#{@hyphenated_attribute}" }
        alert "#{data.files[0].name} is a #{@get_media_type(data.files[0])} file. Only #{@allowed_types.join(", ")} files are allowed."
      
  set_content_type: ->
    form_data = $(@element_id).data('form-data')
    form_data["Content-Type"] = @file.type
    
    $( @element_id ).fileupload(
      formData: form_data
    )
    
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
    triggerEvent "anaconda:file-upload-completed", { file: @file, resource: "#{@hyphenated_resource}-#{@hyphenated_attribute}" }
    # DLog "#{@file.name} completed uploading"
    # DLog @file

    $( @element_id ).siblings( "input[data-#{@hyphenated_resource}-#{@hyphenated_attribute}-file-path]" ).val( @key.replace("${filename}", @file.name) )
    $( @element_id ).siblings( "input[data-#{@hyphenated_resource}-#{@hyphenated_attribute}-filename]" ).val( @file.name )
    $( @element_id ).siblings( "input[data-#{@hyphenated_resource}-#{@hyphenated_attribute}-size]" ).val( @file.size )
    $( @element_id ).siblings( "input[data-#{@hyphenated_resource}-#{@hyphenated_attribute}-type]" ).val( @file.type )
    $( @element_id ).siblings( "input[data-#{@hyphenated_resource}-#{@hyphenated_attribute}-original-filename]" ).val( @file.name )
    $( @element_id ).siblings( "input[data-#{@hyphenated_resource}-#{@hyphenated_attribute}-stored-privately]" ).val( @stored_privately() )

    @upload_in_progress = false;
    @upload_completed = true;
    @upload_manager().upload_completed()
    
  remove_file: ->
    triggerEvent "anaconda:remove-file", { resource: "#{@hyphenated_resource}-#{@hyphenated_attribute}" }
    $("a[data-remove-#{@hyphenated_resource}-#{@hyphenated_attribute}]").hide()
    $( @element_id ).siblings( "input[data-#{@hyphenated_resource}-#{@hyphenated_attribute}-file-path]" ).val("")
    $( @element_id ).siblings( "input[data-#{@hyphenated_resource}-#{@hyphenated_attribute}-filename]" ).val("")
    $( @element_id ).siblings( "input[data-#{@hyphenated_resource}-#{@hyphenated_attribute}-size]" ).val("")
    $( @element_id ).siblings( "input[data-#{@hyphenated_resource}-#{@hyphenated_attribute}-type]" ).val("")
    $( @element_id ).siblings( "input[data-#{@hyphenated_resource}-#{@hyphenated_attribute}-original-filename]" ).val("")
    $( @element_id ).siblings( "input[data-#{@hyphenated_resource}-#{@hyphenated_attribute}-stored-privately]" ).val("")