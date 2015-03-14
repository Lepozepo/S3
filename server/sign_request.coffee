Meteor.methods
	_s3_sign: (ops={}) ->
		@unblock()
		check ops,Object
		# ops.expiration: the signature expires after x milliseconds | defaults to 30 minutes
		# ops.path
		# ops.file_type
		# ops.file_name
		# ops.file_size
		# ops.acl
		# ops.bucket

		_.defaults ops,
			expiration:1800000
			path:""
			bucket:S3.config.bucket
			acl:"public-read"
			region:S3.config.region

		expiration = new Date Date.now() + ops.expiration
		expiration = expiration.toISOString()

		key = "#{ops.path}/#{ops.file_name}"

		policy =
			"expiration":expiration
			"conditions":[
				["content-length-range",0,ops.file_size]
				{"key":key}
				{"bucket":ops.bucket}
				{"Content-Type":ops.file_type}
				{"acl":ops.acl}
				{"Content-Disposition":"inline; filename='#{ops.file_name}'"}
			]

		# Encode the policy
		policy = Buffer(JSON.stringify(policy), "utf-8").toString("base64")

		# Sign the policy
		signature = calculate_signature policy

		# Identify post_url
		if ops.region is "us-east-1" or ops.region is "us-standard"
			post_url = "https://#{ops.bucket}.s3.amazonaws.com"
		else
			post_url = "https://#{ops.bucket}.s3-#{ops.region}.amazonaws.com"

		# Return results
		policy:policy
		signature:signature
		access_key:S3.config.key
		post_url:post_url
		url:"#{post_url}/#{key}".replace("https://","http://")
		secure_url:"#{post_url}/#{key}"
		relative_url:"/#{key}"
		bucket:ops.bucket
		acl:ops.acl
		key:key
		file_type:ops.file_type
		file_name:ops.file_name


crypto = Npm.require("crypto")
calculate_signature = (policy) ->
	crypto.createHmac("sha1", S3.config.secret)
		.update(new Buffer(policy, "utf-8"))
		.digest("base64")



