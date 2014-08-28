Package.describe({
	name:"lepozepo:s3",
	summary: "Upload files to S3. Allows use of Knox Server-Side.",
	version:"3.0.1",
	git:"https://github.com/Lepozepo/S3"
});

Npm.depends({
	knox: "0.8.5"
});

Package.on_use(function (api) {
	//Need service-configuration to use Meteor.method
	// api.versionsFrom('METEOR-CORE@0.9.0-atm');
	api.use(["underscore@1.0.0", "ejson@1.0.0","service-configuration@1.0.0"], ["client", "server"]);
	api.use(["ui@1.0.0","templating@1.0.0","spacebars@1.0.0"], "client");
	api.add_files("client/blocks.html", "client");
	api.add_files("client/events.js", "client");
	api.add_files("s3server.js", "server");

	//Allows user access to Knox
	api.export && api.export("Knox","server");
	api.export && api.export("S3","server");
});