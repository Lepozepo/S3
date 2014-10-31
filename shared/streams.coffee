if Meteor.isClient
	S3.stream.on "upload", (id,operation) ->
		S3.collection.update id,operation

if Meteor.isServer
	S3.stream.permissions.read (user,event) ->
		return true

Meteor.startup ->
	_.extend S3, chunk_size: 1024 * 1024 * 5.3
