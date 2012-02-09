# #Namespace `TYPO3.FormBuilder.View.Editor`#
#
# This file implements all editors related to Finishers.
#
# Contains the following classes:
#
# * Editor.FinisherEditor
#
# ***
# ##Class Editor.FinisherEditor##
#
# TODO
TYPO3.FormBuilder.View.ElementOptionsPanel.Editor.FinisherEditor = TYPO3.FormBuilder.View.ElementOptionsPanel.Editor.AbstractCollectionEditor.extend {
	# ###Public Properties###
	# * `availableFinishers`: JSON object of available validators, where each validator has the following options:
	#
	#    * `label`: human-readable label of the validator
	#    * `sorting`: sorting index to be used for the validator
	#    * `name`: Validator class name, if not specified the `TYPO3.FormBuilder.View.ElementOptionsPanel.Editor.ValidatorEditor.DefaultValidatorEditor` is used.
	#    * `options`: Validator options to be set (JSON object)
	#    * `required`: (boolean) if TRUE; it is required validator which is not de-selectable
	availableFinishers: null,

	# ***
	# ###Private###

	availableCollectionElementsBinding: 'availableFinishers'
	templateName: 'FinisherEditor'

	prompt: 'Select a finisher to add'

	propertyPath: 'finishers'
}

TYPO3.FormBuilder.View.ElementOptionsPanel.Editor.FinisherEditor.EmailFinisherEditor = TYPO3.FormBuilder.View.ElementOptionsPanel.Editor.ValidatorEditor.DefaultValidatorEditor.extend {
	templateName: 'Finisher-Email'

	availableFormats: null,

	format: ((k, v) ->
		if arguments.length >= 2
			@setPath('currentCollectionElement.options.format', v.key)

		chosenFormatKey = @getPath('currentCollectionElement.options.format')
		for format in @get('availableFormats')
			return format if format.key == chosenFormatKey
		return null
	).property('availableFormats').cacheable()
}