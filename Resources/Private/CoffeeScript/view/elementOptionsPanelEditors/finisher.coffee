# <!--
# This file is part of the Neos.Form.YamlBuilder package.
#
# (c) Contributors of the Neos Project - www.neos.io
#
# This package is Open Source Software. For the full copyright and license
# information, please view the LICENSE file which was distributed with this
# source code.
# -->


# #Namespace `Neos.Form.YamlBuilder.View.Editor`#
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
# This is an editor for all finishers. They are defined using the `availableFinishers` property.
Neos.Form.YamlBuilder.View.ElementOptionsPanel.Editor.FinisherEditor = Neos.Form.YamlBuilder.View.ElementOptionsPanel.Editor.AbstractCollectionEditor.extend {
	# ###Public Properties###
	# * `availableFinishers`: JSON object of available validators, where each validator has the following options:
	#
	#    * `label`: human-readable label of the validator
	#    * `sorting`: sorting index to be used for the validator
	#    * `name`: Validator class name, if not specified the `Neos.Form.YamlBuilder.View.ElementOptionsPanel.Editor.ValidatorEditor.DefaultValidatorEditor` is used.
	#    * `options`: Validator options to be set (JSON object)
	#    * `required`: (boolean) if TRUE; it is required validator which is not de-selectable
	availableFinishers: null,

	# ***
	# ###Private###

	availableCollectionElementsBinding: 'availableFinishers'
	templateName: 'ElementOptionsPanel-FinisherEditor'

	prompt: 'Select a finisher to add'

	propertyPath: 'finishers'
}

# ***
# ##Class FinisherEditor.EmailFinisherEditor
#
# view with extra logic for the email finisher; handling the "format" option
# of the email correctly.
Neos.Form.YamlBuilder.View.ElementOptionsPanel.Editor.FinisherEditor.EmailFinisherEditor = Neos.Form.YamlBuilder.View.ElementOptionsPanel.Editor.ValidatorEditor.DefaultValidatorEditor.extend {
	templateName: 'Finisher-EmailEditor'

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
