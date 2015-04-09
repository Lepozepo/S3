Package.describe({
	name:"lepozepo:s3",
	summary: "Upload files to S3. Allows use of Knox Server-Side.",
	version:"5.1.1",
	git:"https://github.com/Lepozepo/S3"
});

Npm.depends({
	knox: "0.9.2",
	"stream-buffers":"2.1.0",
	"aws-sdk":"2.1.14"
});

Package.on_use(function (api) {
	api.versionsFrom('METEOR@1.0');

	api.use(["underscore","check","coffeescript","service-configuration"], ["client", "server"]);

	// Client
	api.add_files("client/functions.coffee", "client");

	// Server
	api.add_files("server/startup.coffee", "server");
	api.add_files("server/sign_request.coffee", "server");
	api.add_files("server/delete_object.coffee", "server");

	//Allows user access to Knox
	api.export && api.export("Knox","server");

	//Allows user access to AWS-SDK
	api.export && api.export("AWS","server");

});
