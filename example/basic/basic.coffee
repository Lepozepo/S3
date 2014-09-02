if Meteor.isClient
	Template.basic.helpers
		"files": -> S3.collection.find()

	Template.basic.events
		"click button": (event) ->
			S3.upload $("input.file_bag")[0].files,"/tester",(result) ->
				console.log result

if Meteor.isServer
	S3.config =
		key:"yourkey"
		secret:"yoursecret"
		bucket:"yourbucket"


