S3 = 
	collection: new Meteor.Collection(null)
	stream: new Meteor.Stream("s3_stream")

	upload: (files,path,callback) ->
		_.each files, (file) ->
			S3._upload_file file, path, (error, result) ->
				if not error
					console.log "Success uploading file"
				else
					console.log "Error uploading file"

	_upload_file: (file,path,callback) ->
		# console.log "Upload file in chunks"
		chunk_size = 1024 * 1024 * 2
		chunks = Math.ceil file.size / chunk_size

		if not _.has file, "id"
			if chunk_size > file.size
				chunk_end = file.size
			else
				chunk_end = chunk_size

			file.id = S3.collection.insert
				file_data:
					size:file.size
					chunks:chunks
					chunk_size:chunk_size
					uploaded_chunks:0
					chunk_start:0
					chunk_end:chunk_end
					path:path

			S3._upload_chunks file, (error,result) ->
				if not error
					console.log result
					callback and callback(null,"success")
				else
					console.log error
					callback and callback("failed")

	_upload_chunks: (file,callback) ->
		# console.log "Upload chunks"
		cFile = S3.collection.findOne file.id

		if cFile.file_data.uploaded_chunks isnt cFile.file_data.chunks
			chunk = file.slice cFile.file_data.chunk_start,cFile.file_data.chunk_end

			S3._upload_chunk chunk, cFile.file_data.path, (error,result) ->
				if not error
					if cFile.file_data.chunk_end + cFile.file_data.chunk_size >= cFile.file_data.size
						# console.log "Chunk Uploaded"
						S3.collection.update file.id,
							$set:
								"file_data.uploaded_chunks":cFile.file_data.chunks
								"file_data.chunk_start":cFile.file_data.size
								"file_data.chunk_end":cFile.file_data.size

						callback and callback(null,result)
					else
						# console.log "Chunk Uploaded, uploading next one"
						S3.collection.update file.id,
							$inc:
								"file_data.uploaded_chunks":1
								"file_data.chunk_start":cFile.file_data.chunk_size
								"file_data.chunk_end":cFile.file_data.chunk_size

						S3._upload_chunks file, (error,result) ->
							if not error
								callback and callback(null,"success")
							else
								callback and callback("failed")

	_upload_chunk: (chunk,path,callback) ->
		# console.log "Upload chunk"
		reader = new FileReader

		reader.onload = ->
			chunk.data = new Uint8Array(reader.result)
			# extension = _.last chunk.name.split(".")
			# chunk.id_name = Random.id() + "." + extension

			# console.log "Send to server for upload"
			callback and callback(null,"success")
			# file.id = S3.collection.insert({})

			# Meteor.call "_S3upload",file,path,(err,res) ->
			# 	if err
			# 		S3.collection.remove file.id
			# 		console.log err

			# 	callback and callback(err,res)

		reader.readAsArrayBuffer chunk

	delete: (path,callback) ->
		Meteor.call "_S3delete", path, (err,res) ->
			callback and callback(err,res)

