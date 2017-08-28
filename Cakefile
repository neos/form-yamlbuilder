fs     = require 'fs'
{exec} = require 'child_process'

appFiles  = [
	# omit src/ and .coffee to make the below lines a little shorter
	'app'
	'utility'
	'model'
	'view'
	'view/application'
	'view/header'
	'view/stage'
	'view/structurePanel'
	'view/insertElementsPanel'
	'view/elementOptionsPanel'
	'view/elementOptionsPanelEditors/collectionEditor'
	'view/elementOptionsPanelEditors/basic'
	'view/elementOptionsPanelEditors/grid'
	'view/elementOptionsPanelEditors/validator'
	'view/elementOptionsPanelEditors/finisher'
]

consoleOutput = (error, stdout, stderr) ->
	console.log('Stdout: ' + stdout)
	console.log('Stderr: ' + stderr)
	if error
		console.log('exec error: ' + error)

task 'build', 'Build single application file from source files (CoffeeScript and SASS)', ->
	appContents = new Array
	remaining = appFiles.length
	exec 'sass --compass Resources/Private/Sass/FormBuilder.scss Resources/Public/Css/FormBuilder.css', consoleOutput

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
	wrapCssFile('Resources/Public/Library/SlickGrid/slick.grid', '#neos-form-yamlbuilder-elementOptionsPanel {')
	wrapCssFile('Resources/Public/Library/jQuery-contextMenu/jquery.contextMenu', '#neos-form-yamlbuilder-elementSidebar, #neos-form-yamlbuilder-elementOptionsPanel {')

task 'buildDocumentation', 'build JS api documentation with docco-husky', ->
	exec "docco-husky Resources/Private/CoffeeScript", consoleOutput
