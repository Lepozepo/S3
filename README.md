# Amazon S3 Uploader
S3 provides a simple way for uploading files to the Amazon S3 service with a progress bar. This is useful for uploading images and files that you want accesible to the public. S3 is built on [Knox](https://github.com/LearnBoost/knox) and [AWS-SDK](https://github.com/aws/aws-sdk-js). Both modules are made available on the server after installing this package.

If you want to keep using the older version of this package (pre 0.9.0) check it out using `meteor add lepozepo:s3@=3.0.1`

If you want to keep using the version of this package that uses server resources to upload files check it out using `meteor add lepozepo:s3@=4.1.3`

**S3 now uploads directly from the client to Amazon. Client files will not touch your server.**

## Migrating from 4.1.3 to 5.x.x
* S3.upload path parameter: "" is now root instead of "/".
* Methods:
	* _S3upload, _S3_abort_mpu, _S3_multipart_upload, and _S3_multipart_close have been destroyed
	* _S3delete has been renamed to _s3_delete
* Infrastructure:
	* Package no longer uses lepozepo:streams

## Installation

``` sh
$ meteor add lepozepo:s3
```

## How to use

### Step 1
Define your Amazon S3 credentials. SERVER SIDE.

``` javascript
S3.config = {
	key: 'amazonKey',
	secret: 'amazonSecret',
	bucket: 'bucketName'
};
```

### Step 2
Create a file input and progress indicator. CLIENT SIDE.

``` handlebars
<template name="s3_tester">
	<input type="file" class="file_bag">
	<button class="upload">Upload</button>

	{{#each files}}
		<p>{{percent_uploaded}}</p>
	{{/each}}
</template>
```

### Step 3
Create a function to upload the files and a helper to see the uploads progress. CLIENT SIDE.

``` javascript
Template.s3_tester.events({
	"click button.upload": function(){
		var files = $("input.file_bag")[0].files

		S3.upload({
				files:files,
				path:"subfolder"
			},function(e,r){
				console.log(r);
		});
	}
})

Template.s3_tester.helpers({
	"files": function(){
		return S3.collection.find();
	}
})
```

## Create your Amazon S3
For all of this to work you need to create an aws account. On their website create navigate to S3 and create a bucket. Navigate to your bucket and on the top right side you'll see your account name. Click it and go to Security Credentials. Once you're in Security Credentials create a new access key under the Access Keys (Access Key ID and Secret Access Key) tab. This is the info you will use for the first step of this plug. Go back to your bucket and select the properties OF THE BUCKET, not a file. Under Static Website Hosting you can Enable website hosting, to do that first upload a blank index.html file and then enable it. YOU'RE NOT DONE.

You need to set permissions so that everyone can see what's in there. Under the Permissions tab click Edit CORS Configuration and paste this:

``` xml
<?xml version="1.0" encoding="UTF-8"?>
<CORSConfiguration xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
	<CORSRule>
		<AllowedOrigin>*</AllowedOrigin>
		<AllowedMethod>PUT</AllowedMethod>
		<AllowedMethod>POST</AllowedMethod>
		<AllowedMethod>GET</AllowedMethod>
		<AllowedMethod>HEAD</AllowedMethod>
		<MaxAgeSeconds>3000</MaxAgeSeconds>
		<AllowedHeader>*</AllowedHeader>
	</CORSRule>
</CORSConfiguration>
```

Save it. Now click Edit bucket policy and paste this, REPLACE THE BUCKET NAME WITH YOUR OWN:

``` javascript
{
	"Version": "2008-10-17",
	"Statement": [
		{
			"Sid": "AllowPublicRead",
			"Effect": "Allow",
			"Principal": {
				"AWS": "*"
			},
			"Action": "s3:GetObject",
			"Resource": "arn:aws:s3:::YOURBUCKETNAMEHERE/*"
		}
	]
}
```

Enjoy, this took me a long time to figure out and I'm sharing it so that nobody has to go through all that.
__NOTE:__ It might take a couple of hours before you can actually start uploading to S3. Amazon takes some time to make things work.

## API

### S3 (CLIENT SIDE)

#### S3.collection
This is a null Meteor.Collection that exists only on the users client. After the user leaves the page or refreshes, the collection disappears forever.

#### S3.upload(ops,callback)
This is the upload function that manages all the dramatic things you need to do for something so essentially simple.

__Parameters:__
*	__ops.files _[REQUIRED]_:__ Must be a FileList object. You can get this via jQuery via $("input[type='file']")[0].files
*	__ops.path:__ Must be in this format ("folder/other_folder"). So basically never start with "/" and never end with "/".
*	__callback:__ A function that is run after the upload is complete returning an Error as the first parameter (if there is one), and a Result as the second.
*	__Result:__ The returned value of the callback function if there is no error. It returns an object with these keys:
	*	__loaded:__ Integer (bytes)
	*	__total:__ Integer (bytes)
	*	__percent_uploaded:__ Integer (out of 100)
	*	__uploader:__ String (describes which uploader was used to upload the file)
	*	__url:__ String (S3 hosted URL)
	*	__secure_url:__ String (S3 hosted URL for https)
	*	__relative_url:__ String (S3 URL for delete operations, this is what you should save in your DB to control delete)

#### S3.delete(path,callback)
This function permanently destroys a file located in your S3 bucket. It still needs more work for security in the form of allow/deny rules.

__Parameters:__
*	__path:__ Must be in this format ("/folder/other_folder/file.extension"). So basically always start with "/" and never end with "/". This is required.
*	__callback:__ A function that is run after the upload is complete returning an Error as the first parameter (if there is one), and a Result as the second.

### S3 (SERVER SIDE)

#### S3.config
This is where you define your key, secret, and bucket.

``` javascript
S3.config = {
	key: 'amazonKey',
	secret: 'amazonSecret',
	bucket: 'bucketName'
};
```

#### S3.stream
This is the meteor stream that is created between the server and the S3.collection object on the client to relay information. You probably don't need access to this.

#### S3.knox
The current knox client.


#### Developer Notes
http://docs.aws.amazon.com/AWSJavaScriptSDK/latest/frames.html
https://github.com/Differential/meteor-uploader/blob/master/lib/UploaderFile.coffee#L169-L178

http://docs.aws.amazon.com/AmazonS3/latest/API/sigv4-auth-using-authorization-header.html
http://docs.aws.amazon.com/general/latest/gr/sigv4-signed-request-examples.html
https://github.com/CulturalMe/meteor-slingshot/blob/master/services/aws-s3.js
