Meteor.methods
	_s3_sign: (ops={}) ->
		@unblock()
		# ops.expiration: the signature expires after x milliseconds | defaults to 30 minutes
		# ops.path
		# ops.file_type
		# ops.file_name
		# ops.file_size
		# ops.acl
		# ops.bucket
		# ops.server_side_encryption
		# ops.content_disposition

		_.defaults ops,
			expiration:1800000
			path:""
			bucket:S3.config.bucket
			acl:"public-read"
			region:S3.config.region
			server_side_encryption:false
			content_disposition:"inline"

		check ops,
			expiration:Number
			path:String
			bucket:String
			acl:String
			region:String
			server_side_encryption:Boolean
			file_type:String
			file_name:String
			file_size:Number
			content_disposition:String

		expiration = new Date Date.now() + ops.expiration
		expiration = expiration.toISOString()

		if _.isEmpty ops.path
			key = "#{ops.file_name}"
		else
			key = "#{ops.path}/#{ops.file_name}"

		meta_uuid = Random.id()
		meta_date = "#{moment().format('YYYYMMDD')}T000000Z"
		meta_credential = "#{S3.config.key}/#{moment().format('YYYYMMDD')}/#{ops.region}/s3/aws4_request"
		policy =
			"expiration":expiration
			"conditions":[
				["content-length-range",0,ops.file_size]
				{"key":key}
				{"bucket":ops.bucket}
				{"Content-Type":ops.file_type}
				{"acl":ops.acl}
				{"x-amz-algorithm": "AWS4-HMAC-SHA256"}
				{"x-amz-credential": meta_credential}
				{"x-amz-date": meta_date }
				{"x-amz-meta-uuid": meta_uuid}
			]
		if ops.content_disposition
			policy["conditions"].push({"Content-Disposition": ops.content_disposition})
		if ops.server_side_encryption
			policy["conditions"].push({"x-amz-server-side-encryption": "AES256"})

		# Encode the policy
		policy = new Buffer(JSON.stringify(policy), "utf-8").toString("base64")

		# Sign the policy
		signature = calculate_signature policy, ops.region

		# Identify post_url
		if ops.region is "us-east-1" or ops.region is "us-standard"
			post_url = "https://s3.amazonaws.com/#{ops.bucket}"
		else
			post_url = "https://s3-#{ops.region}.amazonaws.com/#{ops.bucket}"

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
		meta_uuid:meta_uuid
		meta_date:meta_date
		meta_credential:meta_credential


# crypto = Npm.require("crypto")
Crypto = Npm.require "crypto-js"
moment = Npm.require "moment"
{HmacSHA256} = Crypto

calculate_signature = (policy, region) ->
	kDate = HmacSHA256(moment().format("YYYYMMDD"), "AWS4" + S3.config.secret);
	kRegion = HmacSHA256(region, kDate);
	kService = HmacSHA256("s3", kRegion);
	signature_key = HmacSHA256("aws4_request", kService);

	HmacSHA256 policy, signature_key
		.toString Crypto.enc.Hex


