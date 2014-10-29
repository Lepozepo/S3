#Start up knox
Knox = Npm.require "knox"
AWS = Npm.require "aws-sdk"

#Server side configuration variables
@S3 =
	config:{}
	knox:{}
	stream: new Meteor.Stream("s3_stream")

Meteor.startup ->
	if not _.has S3.config,"key"
		console.log "S3: AWS key is undefined"

	if not _.has S3.config,"secret"
		console.log "S3: AWS secret is undefined"

	if not _.has S3.config,"bucket"
		console.log "S3: AWS bucket is undefined"

	if not _.has(S3.config,"bucket") or not _.has(S3.config,"secret") or not _.has(S3.config,"key")
		return

	S3.knox = Knox.createClient S3.config
	S3.aws = new AWS.S3
		accessKeyId:S3.config.key
		secretAccessKey:S3.config.secret

