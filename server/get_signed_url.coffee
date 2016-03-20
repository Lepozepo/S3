Meteor.methods
  	_getSignedUrl: (key) ->
  		# Obtain a signed URL for a given object. Useful for uploading to private buckets.
  		params = {Bucket: S3.config.bucket, Key: key}
  		return S3.aws.getSignedUrl('getObject', params);
