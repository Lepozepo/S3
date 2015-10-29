Future = Npm.require 'fibers/future'

Meteor.methods
	_s3_delete: (path) ->
		@unblock()
		check path,String

		future = new Future()

		if S3.config.denyDelete
			errorMessage = 'S3.denyDelete is true, so delete was blocked.'
			console.log errorMessage
			e = new Error(errorMessage)
			future.return e

		else
			console.log 'deleting'
			S3.knox.deleteFile path, (e,r) ->
				if e
					console.log e
					future.return e
				else
					future.return true

		future.wait()
