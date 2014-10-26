if Meteor.isClient
	Template.basic.helpers
		"files": -> S3.collection.find()

	Template.basic.events
		"click button.upload": (event) ->
			S3.upload $("input.file_bag")[0].files,"/tester",(error,result) ->
				if error
					console.log error
				else
					console.log result

		"click button.delete": (event) ->
			S3.delete @relative_url, (error,res) ->
				if not error
					console.log res
				else
					console.log error

if Meteor.isServer
	S3.config =
		key:"yourkey"
		secret:"yoursecret"
		bucket:"yourbucket"


