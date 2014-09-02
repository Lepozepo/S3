Package.describe({
	name:"lepozepo:s3",
	summary: "Upload files to S3. Allows use of Knox Server-Side.",
	version:"4.0.0",
	git:"https://github.com/Lepozepo/S3"
});

Npm.depends({
	knox: "0.8.5",
	"stream-buffers":"0.2.5"
});

Package.on_use(function (api) {
	//Need service-configuration to use Meteor.method
	// api.versionsFrom('METEOR-CORE@0.9.0-atm');
	api.use(["underscore@1.0.0", "ejson@1.0.0","service-configuration@1.0.0","coffeescript@1.0.0","lepozepo:streams@0.2.0"], ["client", "server"]);
	api.use(["ui@1.0.0","templating@1.0.0","spacebars@1.0.0"], "client");

	// Client
	api.add_files("client/functions.coffee", "client");

	// Server
	api.add_files("server/methods.coffee", "server");
	api.add_files("server/startup.coffee", "server");

	// Both
	api.add_files("shared/streams.coffee", ["client","server"]);

	//Allows user access to Knox
	api.export && api.export("Knox","server");
	api.export && api.export("S3","server");
	api.export && api.export("S3","client");

});