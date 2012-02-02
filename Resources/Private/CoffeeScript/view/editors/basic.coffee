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

	click: ->
		@set('editMode', true)
}

# special text field which selects its contents when being clicked upon
TYPO3.FormBuilder.View.Editor.IdentifierEditor.TextField = Ember.TextField.extend {
	insertNewline: ->
		@setPath('parentView.editMode', false)
	cancel: ->
		@setPath('parentView.editMode', false)
	focusOut: ->
		@setPath('parentView.editMode', false)
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