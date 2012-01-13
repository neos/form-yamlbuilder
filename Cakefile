fs     = require 'fs'
{exec} = require 'child_process'

appFiles  = [
	# omit src/ and .coffee to make the below lines a little shorter
	'app'
	'utility'
	'model'
	'view'
]

task 'build', 'Build single application file from source files', ->
	appContents = new Array
	remaining = appFiles.length
	for file, index in appFiles then do (file, index) ->
		fs.readFile "Resources/Private/CoffeeScript/#{file}.coffee", 'utf8', (err, fileContents) ->
			throw err if err
			appContents[index] = fileContents
			process() if --remaining is 0

	process = ->
		fs.writeFile 'Resources/Public/JavaScript/app.coffee', appContents.join('\n\n'), 'utf8', (err) ->
			throw err if err
			exec 'coffee --compile Resources/Public/JavaScript/app.coffee', (err, stdout, stderr) ->
				throw err if err
				console.log stdout + stderr
				fs.unlink 'Resources/Public/JavaScript/app.coffee', (err) ->
					throw err if err
					console.log 'Done.'