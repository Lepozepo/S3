@S3 =
	collection: new Meteor.Collection(null)
		# file.name
		# file.type
		# file.size
		# loaded
		# total
		# percent_uploaded
		# uploader
		# status: ["signing","uploading","complete"]
		# url
		# secure_url
		# relative_url

	upload: (ops = {},callback) ->
		# ops.files [OPTIONAL]
			# each needs to run file.type, store in a variable, then send. Either files or ops.file must be provided.
		# ops.file [OPTIONAL]
			# single file upload of javascript type File
		# ops.path [DEFAULT: ""]
			# the folder to upload to: blank string for root folder ""
		# ops.unique_name [DEFAULT: true]
			# modifies the file name to a unique string, if false takes the name of the file. Uploads will overwrite existing files instead.
		# ops.encoding [OPTIONAL: only supports "base64"]
			# overrides file encoding, only supports base64 right now
		# ops.content_disposition [DEFAULT: "inline"]
			# overrides file disposition (inline or attachment)
		# ops.server_side_encryption
			# if true, use server side encryption
		# ops.expiration [DEFAULT: 1800000 (30 mins)]
			# How long before uploads to the file are disabled in ms
		# ops.acl [DEFAULT: "public-read"]
			# Access Control List. Describes who has access to the file. Any of these options:
				# "private",
				# "public-read",
				# "public-read-write",
				# "authenticated-read",
				# "bucket-owner-read",
				# "bucket-owner-full-control",
				# "log-delivery-write"
		# ops.bucket [OVERRIDE REQUIRED SERVER-SIDE]
		# ops.region [OVERRIDE DEFAULT: "us-east-1"]
			# Accepts the following regions:
				# "us-west-2"
				# "us-west-1"
				# "eu-west-1"
				# "eu-central-1"
				# "ap-southeast-1"
				# "ap-southeast-2"
				# "ap-northeast-1"
				# "sa-east-1"
		# ops.uploader [DEFAULT: "default"]
			# key to differentiate multiple uploaders on the same form

		_.defaults ops,
			expiration:1800000
			path:""
			acl:"public-read"
			uploader:"default"
			unique_name:true
			connection:Meteor
			server_side_encryption:false
			content_disposition:"inline"

		if ops.file
			uploadFile(ops.file, ops, callback)
		else
			_.each ops.files, (file) ->
				uploadFile(file, ops, callback)

	delete: (path, callback, connection) ->
		conn = if connection then connection else Meteor
		conn.call "_s3_delete", path, callback

	b64toBlob: (b64Data, contentType, sliceSize) ->
		data = b64Data.split("base64,")
		if not contentType
			contentType = data[0].replace("data:","").replace(";","")

		contentType = contentType
		sliceSize = sliceSize or 512

		byteCharacters = atob data[1]
		byteArrays = []

		for offset in [0...byteCharacters.length] by sliceSize
			slice = byteCharacters.slice offset, offset + sliceSize
			byteNumbers = new Array slice.length

			for i in [0...slice.length]
				byteNumbers[i] = slice.charCodeAt(i)

			byteArray = new Uint8Array byteNumbers

			byteArrays.push byteArray

		blob = new Blob(byteArrays, {type: contentType})
		return blob

uploadFile = (file, ops, callback) ->
	if ops.encoding is "base64"
		if _.isString file
			file = S3.b64toBlob file

	if ops.unique_name or ops.encoding is "base64"
		extension = _.last file.name?.split(".")
		if not extension
			extension = file.type.split("/")[1] # a library of extensions based on MIME types would be better

		file_name = "#{Random.id()}.#{extension}"
	else
		if _.isFunction(file.upload_name)
			file_name = file.upload_name(file)
		else if !_.isEmpty(file.upload_name)
			file_name = file.upload_name
		else
			file_name = file.name

	initial_file_data =
		file:
			name:file_name
			type:file.type
			size:file.size
			original_name:file.name
		loaded:0
		total:file.size
		percent_uploaded:0
		uploader:ops.uploader
		status:"signing"

	id = S3.collection.insert initial_file_data

	ops.connection.call "_s3_sign",
		path:ops.path
		file_name: initial_file_data.file.name
		file_type:file.type
		file_size:file.size
		acl:ops.acl
		bucket:ops.bucket
		region:ops.region
		expiration:ops.expiration
		server_side_encryption:ops.server_side_encryption
		content_disposition:ops.content_disposition
		(error,result) ->
			if result
				# Mark as signed
				S3.collection.update id,
					$set:
						status:"uploading"

				# Prepare data
				form_data = new FormData()
				form_data.append "key", result.key
				form_data.append "acl", result.acl
				form_data.append "Content-Type", result.file_type
				if ops.content_disposition
					form_data.append "Content-Disposition", ops.content_disposition
				form_data.append "X-Amz-Date", result.meta_date
				if ops.server_side_encryption
					form_data.append "x-amz-server-side-encryption", "AES256"
				form_data.append "x-amz-meta-uuid", result.meta_uuid
				form_data.append "X-Amz-Algorithm", "AWS4-HMAC-SHA256"
				form_data.append "X-Amz-Credential", result.meta_credential
				form_data.append "X-Amz-Signature",result.signature

				form_data.append "Policy",result.policy

				form_data.append "file",file

				# Send data
				xhr = new XMLHttpRequest()

				xhr.upload.addEventListener "progress", (event) ->
						S3.collection.update id,
							$set:
								status:"uploading"
								loaded:event.loaded
								total:event.total
								percent_uploaded: Math.floor ((event.loaded / event.total) * 100)
					,false

				xhr.addEventListener "load", ->
					if xhr.status < 400
						S3.collection.update id,
							$set:
								status:"complete"
								percent_uploaded: 100
								url:result.url
								secure_url:result.secure_url
								relative_url:result.relative_url

						callback and callback null,S3.collection.findOne id
					else
						callback and callback true,null

				xhr.addEventListener "error", ->
					callback and callback true,null

				xhr.addEventListener "abort", ->
					console.log "aborted by user"

				xhr.open "POST",result.post_url,true

				xhr.send form_data
			else
				callback and callback error,null
