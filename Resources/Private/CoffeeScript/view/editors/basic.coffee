
TYPO3.FormBuilder.View.Editor.TextOutput = TYPO3.FormBuilder.View.Editor.AbstractEditor.extend {
}

TYPO3.FormBuilder.View.Editor.LabelEditor = TYPO3.FormBuilder.View.Editor.AbstractEditor.extend {
	templateName: 'LabelEditor'
	label: ( (k, v) ->
		if v != undefined
			@setPath('formElement.label', v)
		else
			@getPath('formElement.label')
	).property('formElement').cacheable()
	identifier: ( (k, v)->
		if v != undefined
			@setPath('formElement.identifier', v)
		else
			@getPath('formElement.identifier')
	).property('formElement').cacheable()
}

TYPO3.FormBuilder.View.Editor.TextEditor = TYPO3.FormBuilder.View.Editor.AbstractPropertyEditor.extend {
	### PUBLIC API ###
	label: null

	onValueChange: (->
		@valueChanged()
	).observes('value')

	### PRIVATE ###
	templateName: 'TextEditor'
}