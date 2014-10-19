Future = Npm.require 'fibers/future'
stream_buffers = Npm.require "stream-buffers"

Meteor.methods
	_S3upload: (file,path) ->
		@unblock()

		buffer = new Buffer(file.data)
		file_stream_buffer = new stream_buffers.ReadableStreamBuffer
			frequency:10
			chunkSize:2048

		file_stream_buffer.put(buffer)
		headers =
			"Content-Type": file.type
			"Content-Length": buffer.length

		path = "#{path}/#{file.id_name}"

		future = new Future()
		stream = S3.knox.putStream file_stream_buffer,path,headers, (err,result) ->
			if result
				emit = 
					total_uploaded:result.bytes
					percent_uploaded:100
					uploading:false
					url: S3.knox.http(path)
					secure_url: S3.knox.https(path)
					relative_url:path

				S3.stream.emit "upload", file.id,
					$set:emit

				future.return emit
			else
				console.log err
				future.return err

		stream.on "progress", (progress) ->
			S3.stream.emit "upload", file.id,
				$set:
					total_uploaded:progress.written
					percent_uploaded:progress.percent
					uploading:true

		stream.on "error", (error) ->
			console.log error

		future.wait()

	_S3_multipart_upload: (file,path) ->
		@unblock()

		buffer = new Buffer(file.data)
		file_stream_buffer = new stream_buffers.ReadableStreamBuffer
			frequency:10
			chunkSize:2048

		file_stream_buffer.put(buffer)
		headers =
			"Content-Type": file.ftype
			"Content-Length": buffer.length

		path = "#{path}/#{file.id_name}"

		#If no upload id then create it and save it to client for reuse
		if not file.upload_id
			future = new Future()
			S3.aws.createMultipartUpload
				Bucket:S3.config.bucket
				Key:S3.config.key
				(error,result) ->
					if not error
						console.log "Started upload with #{result.UploadId}"
						future.return result.UploadId
						S3.stream.emit "upload", file.id,
							$set:
								file_data:
									upload_id:result.UploadId
					else
						console.log error
						future.return false

		if file.upload_id or (future and future.wait())
			upload_id = file.upload_id or future.wait()

			future2 = new Future()
			S3.aws.uploadPart
				Bucket:S3.config.bucket
				Key:S3.config.key
				PartNumber:file.chunk_id
				UploadId:upload_id
				Body:file_stream_buffer
				(err,result) ->
					if result
						emit =
							total_uploaded:result.bytes
							percent_uploaded:file.size / file.total_size
							uploading:true
							url: S3.knox.http(path)
							secure_url: S3.knox.https(path)
							relative_url:path

						S3.stream.emit "upload",file.id,
							$set:emit
							$push:
								"file_data.parts":
									ETag:result.ETag
									PartNumber:file.chunk_id

						future2.return emit
					else
						console.log err
						future2.return err

			future2.wait()

	_S3_multipart_upload_close: (cFile) ->
		@unblock()
		console.log "Close and assemble upload"

		future = new Future()
		S3.aws.completeMultipartUpload
			Bucket:S3.config.bucket
			Key:S3.config.key
			MultipartUpload:
				Parts:cFile.parts
			(error,result) ->
				if not error
					future.return result
				else
					future.return error

		future.wait()

	_S3_current_mpus: ->
		S3.aws.listMultipartUploads
			Bucket:S3.config.bucket
			(error,result) ->
				if not error
					console.log result.Uploads.length
				else
					console.log error

	_S3delete: (path) ->
		@unblock()

		future = new Future()

		S3.knox.deleteFile path, (e,r) ->
			if e
				console.log e
				future.return e
			else
				future.return true

		future.wait()





