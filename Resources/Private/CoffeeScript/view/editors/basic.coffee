# #Namespace `TYPO3.FormBuilder.View.Editor`#
#
# All views in this file render parts of the inspector for a single form element on the right side
# of the Form Builder.
#
# Contains the following classes:
#
# * Editor.TextOutput
# * Editor.LabelEditor
# * Editor.TextEditor
#
# ***
# ##Class Editor.TextOutput##
#
# This editor can be used to output static text, such as the label of the current form element.
#
# Just make sure to set the `templateName` property and access `formObject` as required.
TYPO3.FormBuilder.View.Editor.TextOutput = TYPO3.FormBuilder.View.Editor.AbstractEditor.extend {
}

# ***
# ##Class Editor.IdentifierEditor##
#
# This editor makes the `identifier` of a form element editable.
#
TYPO3.FormBuilder.View.Editor.IdentifierEditor = TYPO3.FormBuilder.View.Editor.AbstractPropertyEditor.extend {
	templateName: 'IdentifierEditor'

	propertyPath: 'identifier'

	# ###Private###

	editMode: false

	textFieldValue: null

	validationErrorMessage: null

	validate: (v) ->
		if v == ''
			@set('validationErrorMessage', 'You need to set an identifier!')
			return false
		if !v.match(/^[a-z][a-zA-Z0-9-_]*$/)
			@set('validationErrorMessage', 'This is no valid identifier')
			return false

		elementsWithIdentifier = []
		findFormElementsWithIdentifiers = (el) ->
			if el.get('identifier') == v
				elementsWithIdentifier.push(v)

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

	commit: ->
		if @validate(@get('textFieldValue'))
			@set('value', @get('textFieldValue'))
			@set('editMode', false)
			return true
		else
			return false
	tryToCommit: ->
		if !@commit()
			@abort()
	abort: ->
		@set('editMode', false)
	click: ->
		if !@get('editMode')
			@set('textFieldValue', @get('value'))
			@set('editMode', true)
}

# special text field which selects its contents when being clicked upon
TYPO3.FormBuilder.View.Editor.IdentifierEditor.TextField = Ember.TextField.extend {
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
TYPO3.FormBuilder.View.Editor.TextEditor = TYPO3.FormBuilder.View.Editor.AbstractPropertyEditor.extend {
	label: null

	onValueChange: (->
		@valueChanged()
	).observes('value')

	templateName: 'TextEditor'
}

# ***
# ##Class Editor.RemoveElementEditor##
#
# Displays button to remove this formElement.
TYPO3.FormBuilder.View.Editor.RemoveElementEditor = TYPO3.FormBuilder.View.Editor.AbstractEditor.extend {
	templateName: 'RemoveElementEditor'
	remove: ->
		@get('formElement').removeWithConfirmationDialog()
}