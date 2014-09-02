if Meteor.isClient
	S3.stream.on "upload", (data,id) ->
		S3.collection.update id,data

if Meteor.isServer
	S3.stream.permissions.read (user,event) ->
		return true
