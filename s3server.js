Knox = Npm.require("knox");
var Future = Npm.require('fibers/future');

var knox;
var S3;

Meteor.methods({
	S3config:function(obj){
		knox = Knox.createClient(obj);
		S3 = {directory:obj.directory || "/"};
	},
	S3upload:function(file,context,callback){
		var future = new Future();

		var extension = (file.name).match(/\.[0-9a-z]{1,5}$/i);
		file.name = Meteor.uuid()+extension;
		var path = S3.directory+file.name;

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
