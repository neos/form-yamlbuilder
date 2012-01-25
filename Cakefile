fs     = require 'fs'
{exec} = require 'child_process'

appFiles  = [
	# omit src/ and .coffee to make the below lines a little shorter
	'app'
	'utility'
	'model'
	'view'
]

consoleOutput = (error, stdout, stderr) ->
	console.log('Stdout: ' + stdout)
	console.log('Stderr: ' + stderr)
	if error
		console.log('exec error: ' + error)

task 'build', 'Build single application file from source files (CoffeeScript and SASS)', ->
	appContents = new Array
	remaining = appFiles.length
	exec 'sass --compass Resources/Private/Sass/Style.scss Resources/Public/style.css', consoleOutput

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


# file path without ".css" suffix
wrapCssFile = (filePath, beforeWrapper, afterWrapper = '}') ->
	data = []
	data[0] = beforeWrapper
	data[1] = fs.readFileSync(filePath + '.css')
	data[2] = afterWrapper
	fs.writeFileSync(filePath + '.wrapped.scss', data.join('\n'))
	exec "sass #{filePath}.wrapped.scss #{filePath}.wrapped.css", consoleOutput


task 'modifyExternalLibraryCss', 'Modify external library CSS by wrapping it and compiling it with SASS', ->
	wrapCssFile('Resources/Public/Library/dynatree-1.2.0/src/skin/ui.dynatree', '#leftSidebar {')
	wrapCssFile('Resources/Public/Library/SlickGrid/slick.grid', '#rightSidebar {')

