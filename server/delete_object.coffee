Future = Npm.require 'fibers/future'

Meteor.methods
	_s3_delete: (path) ->
		@unblock()
		check path,String

		future = new Future()

		if S3.rules?.delete
			delete_context = _.extend this,
				s3_delete_path:path

			auth_function = _.bind S3.rules.delete,delete_context
			if not auth_function()
				throw new Meteor.Error "Unauthorized", "Delete not allowed"

		S3.knox.deleteFile path, (e,r) ->
			if e
				future.return e
			else
				future.return true

		future.wait()
