Template.S3.events({
	'change input[type=file]': function (e,helper) {
		var context = this;

		if(helper.data && _.has(helper.data,"callback")){
			var callback = helper.data.callback;
		} else {
			console.log("S3 Error: Helper Block needs a callback function to run");
			return
		}

		var files = e.currentTarget.files;
		_.each(files,function(file){
			var reader = new FileReader;
			var fileData = {
				name:file.name,
				size:file.size,
				type:file.type
			};

			reader.onload = function () {
				fileData.data = new Uint8Array(reader.result);
				Meteor.call("S3upload",fileData,context,callback);
			};

			reader.readAsArrayBuffer(file);

		});
	}
});