Package.describe({
	name:"lepozepo:s3",
	summary: "Upload files to S3. Allows use of Knox Server-Side.",
	version:"5.0.0",
	git:"https://github.com/Lepozepo/S3"
});

Npm.depends({
	knox: "0.9.2",
	"stream-buffers":"2.1.0",
	"aws-sdk":"2.1.14"
});

Package.on_use(function (api) {
	api.versionsFrom('METEOR@1.0');

	api.use(["underscore", "check","coffeescript","service-configuration","lepozepo:streams@0.2.0"], ["client", "server"]);
	// api.use(["ui@1.0.0","templating@1.0.0","spacebars@1.0.0"], "client");

	// Client
	api.add_files("client/functions.coffee", "client");

	// Server
	api.add_files("server/methods.coffee", "server");
	api.add_files("server/startup.coffee", "server");

	// Both
	api.add_files("shared/streams.coffee", ["client","server"]);

	//Allows user access to Knox
	api.export && api.export("Knox","server");
});