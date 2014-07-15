Knox = Npm.require("knox");
var Future = Npm.require('fibers/future');

var knox;
S3 = {};
S3.config = {directory:"/"};

Meteor.startup(function(){
	knox = Knox.createClient(S3.config);
});

Meteor.methods({
	S3upload:function(file,context,callback){
		var future = new Future();

		var extension = (file.name).match(/\.[0-9a-z]{1,5}$/i);
		file.name = Meteor.uuid()+extension;
    var path = ( S3.config.directory === undefined || S3.config.directory === null) ? file.name : S3.config.directory+file.name;

		var buffer = new Buffer(file.data);

		knox.putBuffer(buffer,path,{"Content-Type":file.type,"Content-Length":buffer.length},function(e,r){
			if(!e){
				future.return(path);
			} else {
				console.log(e);
			}
		});

		if(future.wait() && callback){
			var url = knox.http(future.wait());
			Meteor.call(callback,url,context);
			return url;
		}
	},
	S3delete:function(path, callback){
		knox.deleteFile(path, function(e,r) {
			if(e){
				console.log(e);
			}	else if(callback){
				Meteor.call(callback);
			}
		});
	}
});
