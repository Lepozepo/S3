var Knox = Npm.require("knox");
var Future = Npm.require('fibers/future');

var knox;

Meteor.methods({
	S3config:function(obj){
		knox = Knox.createClient(obj);
	},
	S3upload:function(file,callback){
		var future = new Future();

		var extension = (file.name).match(/\.[0-9a-z]{1,5}$/i);
		file.name = Meteor.uuid()+extension;

		var buffer = new Buffer(file.data);

		knox.putBuffer(buffer,"/"+file.name,{"Content-Type":file.type,"Content-Length":buffer.length},function(e,r){
			if(!e){
				var path = "https://s3.amazonaws.com/retrosoda/"+file.name;
				future.return(path);
			} else {
				console.log(e);
			}
		});

		if(future.wait() && callback){
			Meteor.call(callback,future.wait());
		}
	}
});