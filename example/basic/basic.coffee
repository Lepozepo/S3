if Meteor.isClient
	Template.basic.helpers
		"stuff": ->
			_id:"1234"
			name:"Rocket Fuel"


if Meteor.isServer
	S3.config =
		key:"aws_key"
		secret:"aws_secret"
		bucket:"bucket"
		directory:"/tester/"

	Meteor.methods
		save_url: (url,context) ->
			console.log url
			console.log context