# Amazon S3 Uploader
S3 provides a simple way of uploading files to the Amazon S3 service. This is useful for uploading images and files that you want accesible to the public. S3 is built on [Knox](https://github.com/LearnBoost/knox), a module that becomes available server-side after installing this package.

## Installation

``` sh
$ mrt add s3
```

## How to use

### Step 1
Define your Amazon S3 credentials. SERVER SIDE.

``` javascript
Meteor.call("S3config",{
	key: 'amazonKey',
	secret: 'amazonSecret',
	bucket: 'bucketName'
});
```

### Step 2
Create an S3 input with a callback. CLIENT SIDE.

``` handlebars
{{#S3 callback="callbackFunction"}}
	<input type="file">
{{/S3}}
```

### Step 3
Create a callback function that will handle what to do with the generated URL. SERVER SIDE.

``` javascript
Meteor.methods({
	callbackFunction:function(url){
		console.log(url);
	}
});
```

## Notes

I have no clue how to make a progress bar but it'll happen someday. I was able to make that work by modifying [meteor-file](https://github.com/EventedMind/meteor-file) BUT I wasn't able to use it in [Modulus](https://modulus.io/) because their cloud storage service isn't public (so I ended up having to read the file as a base64 image which sucked for performance).