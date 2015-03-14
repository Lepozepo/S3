Future = Npm.require 'fibers/future'

Meteor.methods
	_s3_delete: (path) ->
		@unblock()
		check path,String

		future = new Future()

		S3.knox.deleteFile path, (e,r) ->
			if e
				console.log e
				future.return e
			else
				future.return true

		future.wait()