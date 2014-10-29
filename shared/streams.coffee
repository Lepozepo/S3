if Meteor.isClient
	S3.stream.on "upload", (id,operation) ->
		S3.collection.update id,operation

if Meteor.isServer
	S3.stream.permissions.read (user,event) ->
		return true
