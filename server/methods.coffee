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

				S3.stream.emit("upload",emit,file.id)

				future.return emit
			else
				console.log err
				future.return err

		stream.on "progress", (progress) ->
			upload_stats =
				total_uploaded:progress.written
				percent_uploaded:progress.percent
				uploading:true

			S3.stream.emit("upload",upload_stats,file.id)

		stream.on "error", (error) ->
			console.log error

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





