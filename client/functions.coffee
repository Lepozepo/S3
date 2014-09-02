S3 = 
	collection: new Meteor.Collection(null)
	stream:new Meteor.Stream("s3_stream")

	upload: (files,path,callback) ->
		_.each files, (file) ->
			reader = new FileReader

			reader.onload = ->
				file.data = new Uint8Array(reader.result)
				extension = _.last file.name.split(".")
				file.id_name = Meteor.uuid() + "." + extension
				file.id = S3.collection.insert({})

				Meteor.call "_S3upload",file,path,(err,res) ->
					if err
						S3.collection.remove file.id
						console.log err
					else
						callback && callback(res)

			reader.readAsArrayBuffer(file)

