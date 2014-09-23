if Meteor.isClient
	Template.basic.helpers
		"files": -> S3.collection.find()

	Template.basic.events
		"change :file": (event, template) ->
			console.log 'load'
			console.log event
			filename = getFilename(event)
			f = template.$('.filename').val(filename)

		"click .upload": (event) ->
			S3.upload $("input.file_bag")[0].files,"/tester",(error,result) ->
				console.log result

		"click .delete": (event) ->
			S3.delete @relative_url, (error,res) ->
				console.log error
				console.log res

		"dropped #dropzone": (event) ->
			console.log 'file dropped'
			files = getFiles(event)

			S3.upload files, "/tester", (err, res) ->
				console.log res

if Meteor.isServer
	S3.config =
		key:"myKey"
		secret:"mySecret"
		bucket:"myBucket"
		fileSize:
			min: 490000
			max: 500000

getFiles = (event) ->
	evt = (event.originalEvent || event)
	files = evt.target.files

	unless files and files.length
		files = if evt.dataTransfer then evt.dataTransfer.files else []

getFilename = (event) ->
	evt = (event.originalEvent || event)
	files = evt.target.files

	unless files and files.length
		files = if evt.dataTransfer then evt.dataTransfer.files else []

	if !files
		return 'No file selected'
	else if files.length == 1
		return files[0].name
	else
		return files.length + ' files selected'
