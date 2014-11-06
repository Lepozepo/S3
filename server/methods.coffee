Future = Npm.require 'fibers/future'
stream_buffers = Npm.require "stream-buffers"

#WIP
# current_streaming_chunks = []

# class upload_file
# 	constructor: (data={}) ->
# 		this = data

# 		current_streaming_chunk = _.findWhere current_streaming_chunks,_id:@_id
# 		if current_streaming_chunk
# 			@append()
# 		else
# 			@create()

# 	create: ->
# 		current_streaming_chunks.push =
# 			_id:@_id
# 			buffer:new Buffer @data


Meteor.methods
	_S3upload: (data) ->
		@unblock()

		buffer = new Buffer(data.data)

		#Create a stream to pump data into knox slowly, this should help keep CPU usage steady
		file_stream_buffer = new stream_buffers.ReadableStreamBuffer
			frequency:10 #pump every 10 milliseconds
			chunkSize:2048 * 4 #pump 2048 * 4 bytes

		file_stream_buffer.put(buffer)
		headers =
			"Content-Length": buffer.length
			"Content-Type":data.ftype

		future = new Future()
		stream = S3.knox.putStream file_stream_buffer,data.target_url,headers, (err,result) ->
			if not err and result
				emit = 
					total_uploaded:result.bytes
					percent_uploaded:100
					uploading:false
					url: S3.knox.http(data.target_url)
					secure_url: S3.knox.https(data.target_url)
					relative_url:data.target_url

				S3.stream.emit "upload", data._id,
					$set:emit

				future.return emit
			else
				throw new Meteor.Error "S3.knox.putStream", err

		stream.on "progress", (progress) ->
			S3.stream.emit "upload", data._id,
				$set:
					total_uploaded:progress.written
					percent_uploaded:progress.percent
					uploading:true

		stream.on "error", (error) ->
			throw new Meteor.Error "S3.knox.putStream", error

		future.wait()

	list_S3_mpus: ->
		S3.aws.listMultipartUploads Bucket:S3.config.bucket, (err,res) ->
			if not err
				console.log res
			else
				console.log err

		return

	abort_current_S3_mpus: ->
		S3.aws.listMultipartUploads Bucket:S3.config.bucket, (err,res) ->
			if not err
				_.each res.Uploads, (upload) ->
					S3.aws.abortMultipartUpload
						Bucket:S3.config.bucket
						Key:upload.Key
						UploadId:upload.UploadId
						(error,result) ->
							if not error
								console.log result
							else
								console.log error
			else
				console.log err

		return

	_S3_abort_mpu: (upload = {}) ->
		@unblock()

		S3.aws.abortMultipartUpload
			Bucket:S3.config.bucket
			Key:upload.key
			UploadId:upload.id
			Meteor.bindEnvironment (error,result) ->
				if error
					throw new Meteor.Error "_S3_abort_mpu failed", error

	_S3_multipart_upload: (data) ->
		@unblock()

		buffer = new Buffer(data.data)
		file_stream_buffer = new stream_buffers.ReadableStreamBuffer
			frequency:10
			chunkSize:2048 * 4

		file_stream_buffer.put(buffer)
		future = new Future()

		#If no upload id then create it and save it to client for reuse
		if not data.aws.upload_id
			S3.aws.createMultipartUpload
				Bucket:S3.config.bucket
				Key:data.target_url
				ContentType:data.ftype
				Meteor.bindEnvironment (error,result) ->
					if not error
						aws_stream = S3.aws.uploadPart
							Body:file_stream_buffer
							Bucket:S3.config.bucket
							Key:data.target_url
							PartNumber:data.chunk_number
							UploadId:result.UploadId
							ContentLength:file_stream_buffer.size()

						aws_stream.on "httpUploadProgress", (progress) ->
							uploaded = Math.ceil(((data.read_progress + progress.loaded) / data.size) * 100)
							if uploaded > 100
								uploaded = 100

							S3.stream.emit "upload", data._id,
								$set:
									total_uploaded:data.read_progress + progress.loaded
									percent_uploaded:uploaded
									uploading:true

						aws_stream.on "error", (response) ->
							Meteor.call "_S3_abort_mpu",
								key:data.target_url
								id:data.aws.upload_id
								->
									throw new Meteor.Error "aws_stream",response.message

						aws_stream.on "success", (response) ->
							future.return
								upload_id:result.UploadId
								upload_key:result.Key
								part:
									ETag:response.data.ETag
									PartNumber:data.chunk_number

						aws_stream.send()
					else
						throw new Meteor.Error "aws.createMpu",error

		if data.aws.upload_id
			aws_stream = S3.aws.uploadPart
				Body:file_stream_buffer
				Bucket:S3.config.bucket
				Key:data.target_url
				PartNumber:data.chunk_number
				UploadId:data.aws.upload_id
				ContentLength:file_stream_buffer.size()

			aws_stream.on "httpUploadProgress", (progress) ->
				uploaded = Math.ceil(((data.read_progress + progress.loaded) / data.size) * 100)
				if uploaded > 100
					uploaded = 100

				S3.stream.emit "upload", data._id,
					$set:
						total_uploaded:data.read_progress + progress.loaded
						percent_uploaded:uploaded
						uploading:true

			aws_stream.on "error", (response) ->
				Meteor.call "_S3_abort_mpu",
					key:data.target_url
					id:data.aws.upload_id
					->
						throw new Meteor.Error "aws_stream",response.message

			aws_stream.on "success", (response) ->
				future.return
					upload_id:data.aws.upload_id
					upload_key:data.target_url
					part:
						ETag:response.data.ETag
						PartNumber:data.chunk_number

			aws_stream.send()

		future.wait()

	_S3_multipart_close: (data) ->
		@unblock()

		future = new Future()
		S3.aws.completeMultipartUpload
			Bucket:S3.config.bucket
			Key:data.target_url
			UploadId:data.aws.upload_id
			MultipartUpload:
				Parts:data.aws.Parts
			(error,result) ->
				if not error
					emit = 
						total_uploaded:result.bytes
						percent_uploaded:100
						uploading:false
						url: S3.knox.http(data.target_url)
						secure_url: S3.knox.https(data.target_url)
						relative_url:data.target_url

					S3.stream.emit "upload", data._id,
						$set:emit

					future.return emit
				else
					throw new Meteor.Error "_S3_multipart_close",error

		future.wait()

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





