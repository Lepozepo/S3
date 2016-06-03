#Get Knox and AWS libraries
Knox = Npm.require "knox"

processBrowser = process.browser
process.browser = false
AWS = Npm.require "aws-sdk"
process.browser = processBrowser

#Server side configuration variables
@S3 =
	config:{}
	knox:{}
	aws:{}
	rules:{}

Meteor.startup ->
	if not _.has S3.config,"key"
		console.log "S3: AWS key is undefined"

	if not _.has S3.config,"secret"
		console.log "S3: AWS secret is undefined"

	if not _.has S3.config,"bucket"
		console.log "S3: AWS bucket is undefined"

	if not _.has(S3.config,"bucket") or not _.has(S3.config,"secret") or not _.has(S3.config,"key")
		return

	_.defaults S3.config,
		region:"us-east-1" # us-standard

	S3.knox = Knox.createClient S3.config
	S3.aws = new AWS.S3
		accessKeyId:S3.config.key
		secretAccessKey:S3.config.secret
		region:S3.config.region

