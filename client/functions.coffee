S3 =
	collection: new Meteor.Collection(null)
	stream: new Meteor.Stream("s3_stream")

	upload: (files,path,callback) ->
		results = []
		_.each files, (file) ->
			S3._upload_file file, path, callback

	_upload_file: (file,path,callback) ->
		chunk_size = 1024 * 1024 * 2
		chunks = Math.ceil file.size / chunk_size

		if not _.has file, "id"
			#MULTIPART UPLOAD
			if chunks > 1
				throw new Meteor.Error 500,"File is larger than 2MB","Large files are not yet supported"
				return

				file.id = S3.collection.insert
					file_data:
						size:file.size
						chunks:chunks
						chunk_size:chunk_size
						uploaded_chunks:0
						chunk_start:0
						chunk_end:chunk_size
						path:path
						multipart:true

				S3._upload_chunks file, (error,result) ->
					if not error
						console.log result
						callback and callback(null,"success")
					else
						console.log error
						callback and callback("failed")

			#NORMAL UPLOAD
			if chunks is 1
				file.id = S3.collection.insert
					file_data:
						size:file.size
						path:path
						multipart:false

				reader = new FileReader
				reader.onload = ->
					file.data = new Uint8Array(reader.result)
					extension = _.last file.name.split(".")
					file.id_name = Random.id() + "." + extension

					Meteor.call "_S3upload",file,path,(err,res) ->
						if err
							S3.collection.remove file.id
							console.log err
						callback and callback(err,res)

				reader.readAsArrayBuffer file

	_upload_chunks: (file,callback) ->
		# console.log "Upload chunks"
		cFile = S3.collection.findOne file.id

		if cFile.file_data.uploaded_chunks isnt cFile.file_data.chunks
			chunk = file.slice cFile.file_data.chunk_start,cFile.file_data.chunk_end
			extension = _.last file.name.split(".")
			chunk.id_name = Random.id() + "." + extension
			chunk.id = file.id
			chunk.ftype = file.type
			chunk.total_size = file.size
			chunk.upload_id = cFile.file_data.upload_id
			chunk.chunk_id = cFile.file_data.uploaded_chunks

			S3._upload_chunk chunk, cFile.file_data.path, (error,result) ->
				if not error
					if cFile.file_data.chunk_end + cFile.file_data.chunk_size >= cFile.file_data.size
						# console.log "Chunk Uploaded"
						S3.collection.update file.id,
							$set:
								"file_data.uploaded_chunks":cFile.file_data.chunks
								"file_data.chunk_start":cFile.file_data.size
								"file_data.chunk_end":cFile.file_data.size

						Meteor.call "_S3_multipart_upload_close", S3.collection.findOne file.id, callback
					else
						# console.log "Chunk Uploaded, uploading next one"
						S3.collection.update file.id,
							$inc:
								"file_data.uploaded_chunks":1
								"file_data.chunk_start":cFile.file_data.chunk_size
								"file_data.chunk_end":cFile.file_data.chunk_size

						S3._upload_chunks file, callback

	_upload_chunk: (chunk,path,callback) ->
		reader = new FileReader

		reader.onload = ->
			chunk.data = new Uint8Array(reader.result)

			Meteor.call "_S3_multipart_upload",chunk,path,(err,res) ->
				if err
					S3.collection.remove chunk.id
					console.log err
				callback and callback(err,res)

		reader.readAsArrayBuffer chunk

	delete: (path,callback) ->
		Meteor.call "_S3delete", path, callback

	uploadBase64: (data, objectkey, mimetype, permissions, callback) ->
		#removing the string injected from mgd:camera for using as src of img
		base64data = data.replace(/^data:image\/\w+;base64,/, "")
		console.log base64data

		Meteor.call "_S3_base64_upload",base64data, objectkey, mimetype, permissions, (err,res) ->
			if err
				console.log err
			callback and callback(err,res)
