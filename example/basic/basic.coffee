if Meteor.isClient
	Template.basic.helpers
		"files": -> S3.collection.find()

	Template.basic.events
		"click button.upload": (event) ->
			S3.upload $("input.file_bag")[0].files,"/tester",(error,result) ->
				console.log result

		"click button.delete": (event) ->
			S3.delete @relative_url, (error,res) ->
				console.log error
				console.log res

if Meteor.isServer
	S3.config =
		key:"yourkey"
		secret:"yoursecret"
		bucket:"yourbucket"


