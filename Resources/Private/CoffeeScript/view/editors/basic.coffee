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
# ##Class Editor.LabelEditor##
#
# This editor makes the `identifier` and the `label` of a form element editable.
#
# TODO: if the `identifier` is automatically assigned, update it from the label as soon
# as the label is inserted.
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