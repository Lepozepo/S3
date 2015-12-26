if Meteor.isClient
	Template.basic.helpers
		"files": -> S3.collection.find()

	Template.basic.events
		"click button.upload": (event) ->
			S3.upload
				files:$("input.file_bag")[0].files
				(error,result) ->
					if error
						console.log "Unable to upload"
					else
						console.log result

		"click button.delete": (event) ->
			S3.delete @relative_url, (error,res) =>
				if not error
					console.log res
					S3.collection.remove @_id
				else
					console.log error

if Meteor.isServer
	S3.config =
		key:"yourkey"
		secret:"yoursecret"
		bucket:"yourbucket"
		# region:"us-standard" #default




