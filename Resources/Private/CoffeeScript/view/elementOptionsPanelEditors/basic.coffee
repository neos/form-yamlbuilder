# #Namespace `TYPO3.FormBuilder.View.ElementOptionsPanel.Editor`#
#
# All views in this file render parts of the inspector for a single form element on the right side
# of the Form Builder.
#
# Contains the following classes:
#
# * ElementOptionsPanel.Editor.TextOutput
# * ElementOptionsPanel.Editor.LabelEditor
# * ElementOptionsPanel.Editor.TextEditor
#
# ***
# ##Class Editor.TextOutput##
#
# This editor can be used to output static text, such as the label of the current form element.
#
# Just make sure to set the `templateName` property and access `formObject` as required.
TYPO3.FormBuilder.View.ElementOptionsPanel.Editor.TextOutput = TYPO3.FormBuilder.View.ElementOptionsPanel.Editor.AbstractEditor.extend {
}

# ***
# ##Class Editor.IdentifierEditor##
#
# This editor makes the `identifier` of a form element editable, and
# also validates that the identifier is valid.
#
TYPO3.FormBuilder.View.ElementOptionsPanel.Editor.IdentifierEditor = TYPO3.FormBuilder.View.ElementOptionsPanel.Editor.AbstractPropertyEditor.extend {
	templateName: 'ElementOptionsPanel-IdentifierEditor'

	# ###Private###

	propertyPath: 'identifier'

	# are we currently in edit mode?
	editMode: false

	# current text field value; read when committing etc
	textFieldValue: null

	# valdiation error message which is displayed in the view, if any
	validationErrorMessage: null

	# validate the element:
	#
	# - the identifier must not be empty
	# - it must be valid according to RegEx
	# - it should not exist inside the form yet
	validate: (v) ->
		if v == ''
			@set('validationErrorMessage', 'You need to set an identifier!')
			return false
		if !v.match(/^[a-z][a-zA-Z0-9-_]*$/)
			@set('validationErrorMessage', 'This is no valid identifier. Only lowerCamelCase allowed.')
			return false

		elementsWithIdentifier = []
		findFormElementsWithIdentifiers = (el) ->
			if el.get('identifier') == v
				elementsWithIdentifier.push(el)

			for subRenderable in el.get('renderables')
				findFormElementsWithIdentifiers(subRenderable)

		findFormElementsWithIdentifiers(TYPO3.FormBuilder.Model.Form.get('formDefinition'))

		if elementsWithIdentifier.length == 0
			@set('validationErrorMessage', null)
			return true
		else if elementsWithIdentifier.length == 1 && elementsWithIdentifier[0] == @get('formElement')
			@set('validationErrorMessage', null)
			return true
		else
			@set('validationErrorMessage', 'The identifier is already used')
			return false

	# commit the value if it is valid
	commit: ->
		if @validate(@get('textFieldValue'))
			@set('value', @get('textFieldValue'))
			@set('editMode', false)
			return true
		else
			return false

	# try to commit; and abort if committing did not work
	tryToCommit: ->
		if !@commit()
			@abort()

	# discard the currently edited value
	abort: ->
		@set('editMode', false)

	# switch on edit mode if clicking on the element
	click: ->
		if !@get('editMode')
			@set('textFieldValue', @get('value'))
			@set('editMode', true)
}

# special text field which selects its contents when being clicked upon,
# and triggers `commit(), abort()`, and `tryToCommit()` on the respective events.
TYPO3.FormBuilder.View.ElementOptionsPanel.Editor.IdentifierEditor.TextField = Ember.TextField.extend {
	insertNewline: ->
		@get('parentView').commit()
	cancel: ->
		@get('parentView').abort()
	focusOut: ->
		@get('parentView').tryToCommit()
	didInsertElement: ->
		@$().select()
}


# ***
# ##Class Editor.TextEditor##
#
# Edit a single property specified by `propertyPath` with a text field.
#
# ###Public API###
#
# - `label`: Label of the text field, which should be shown.
TYPO3.FormBuilder.View.ElementOptionsPanel.Editor.TextEditor = TYPO3.FormBuilder.View.ElementOptionsPanel.Editor.AbstractPropertyEditor.extend {
	label: null

	onValueChange: (->
		@valueChanged()
	).observes('value')

	templateName: 'ElementOptionsPanel-TextEditor'
}

# ***
# ##Class Editor.TextareaEditor##
#
# Edit a single property specified by `propertyPath` with a textarea field.
#
# ###Public API###
#
# - `label`: Label of the text field, which should be shown.
TYPO3.FormBuilder.View.ElementOptionsPanel.Editor.TextareaEditor = TYPO3.FormBuilder.View.ElementOptionsPanel.Editor.TextEditor.extend {
	templateName: 'ElementOptionsPanel-TextareaEditor'
}



# ***
# ##Class Editor.RemoveElementEditor##
#
# Displays button to remove this formElement.
TYPO3.FormBuilder.View.ElementOptionsPanel.Editor.RemoveElementEditor = TYPO3.FormBuilder.View.ElementOptionsPanel.Editor.AbstractEditor.extend {
	templateName: 'ElementOptionsPanel-RemoveElement'
	remove: ->
		@get('formElement').removeWithConfirmationDialog()
}