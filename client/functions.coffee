@S3 =
	collection: new Meteor.Collection(null)
	stream: new Meteor.Stream("s3_stream")
	upload: (ops = {},callback) ->
		if not ops.files or ops.files.length is 0
			err = new Meteor.Error "S3.upload","Needs files to upload"
			callback and callback err,null
			throw err

		if not ops.path
			ops.path = "/"

		_.each ops.files, (file) ->
			if file.size and file.size > 0
				ftype = file.type
				new upload_file
					file:file
					ftype:ftype
					path:ops.path
					callback:callback
					encoding:ops.encoding
			else if ops.encoding
				new upload_file
					file:file
					path:ops.path
					callback:callback
					encoding:ops.encoding

	delete: (path,callback) ->
		Meteor.call "_S3delete", path, callback


class upload_file
	constructor: (data = {}) ->
		id = S3.collection.insert
			file_name:data.file.name
			total_uploaded:0
			percent_uploaded:0

		@_id = id
		@file = data.file
		@ftype = data.ftype
		@encoding = data.encoding
		@extension = _.last data.file.name.split(".")
		@id_name = "#{@_id}.#{@extension}"
		@size = data.file.size
		@read_start = 0
		@read_end = S3.chunk_size
		@read_progress = 0 #in bytes
		@chunk_number = 1
		@total_chunks = Math.ceil @size / S3.chunk_size
		@path = data.path
		@target_url = "#{@path}/#{@id_name}".replace(/\/\//g, "/").replace(/^\//g, "")
		@callback = data.callback
		@upload_result = null
		@aws = {Parts:[]}

		@read()

	read: ->
		if @read_progress < @size
			chunk = @file.slice @read_start, @read_end
			@read_start = @read_end
			@read_end += S3.chunk_size

			if @read_end > @size then @read_end = @size

			reader = new FileReader
			reader.onload = =>
				@data = new Uint8Array reader.result

				if @total_chunks is 1
					Meteor.call "_S3upload",this,(err,res) =>
						if not err
							@read_progress += @size
							@chunk_number += 1
							@upload_result = res
							@read()
						else
							S3.collection.remove @_id
							@callback and @callback err,null
							throw new Meteor.Error "_S3upload",err

				if @total_chunks > 1 and (@chunk_number-1) isnt @total_chunks
					Meteor.call "_S3_multipart_upload",this,(err,res) =>
						if not err
							@read_progress += S3.chunk_size
							@chunk_number += 1
							@aws.upload_id = res.upload_id
							@aws.upload_key = res.upload_key
							@aws.Parts.push res.part
							@read()
						else
							S3.collection.remove @_id
							@callback and @callback err,null
							throw new Meteor.Error "_S3_multipart_upload",err

			reader.readAsArrayBuffer chunk

		else if @read_progress >= @size
			if @aws.Parts.length > 1
				Meteor.call "_S3_multipart_close",this,(err,res) =>
					if not err
						result = S3.collection.findOne @_id
						@callback and @callback null,result
					else
						S3.collection.remove @_id
						@callback and @callback err,null
						throw new Meteor.Error "_S3_multipart_close",err
			else
				result = S3.collection.findOne @_id
				@callback and @callback null,result







