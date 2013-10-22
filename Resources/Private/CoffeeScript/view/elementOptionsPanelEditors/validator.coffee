# <!--
# This script belongs to the FLOW3 package "TYPO3.FormBuilder".
#
# It is free software; you can redistribute it and/or modify it under
# the terms of the GNU Lesser General Public License, either version 3
#  of the License, or (at your option) any later version.
#
# The TYPO3 project - inspiring people to share!
# -->


# #Namespace `TYPO3.FormBuilder.View.Editor`#
#
# This file implements all editors related to Validation.
#
# Contains the following classes:
#
# * Editor.RequiredValidatorEditor
# * Editor.ValidatorEditor
# * Editor.ValidatorEditor.DefaultValidatorEditor
# * Editor.ValidatorEditor.MinimumMaximumValidatorEditor
#
# ***
# ##Class Editor.RequiredValidatorEditor##
#
# This view adds a `required` checkbox which selects or deselects the NotEmpty validator from the list of validators.
TYPO3.FormBuilder.View.ElementOptionsPanel.Editor.RequiredValidatorEditor = TYPO3.FormBuilder.View.ElementOptionsPanel.Editor.AbstractPropertyEditor.extend {
	# ***
	# ###Private###
	templateName: 'ElementOptionsPanel-RequiredValidatorEditor'
	propertyPath: 'validators'
	defaultValue: (-> []).property().cacheable()

	# returns TRUE if the required validator is currently configured, FALSE otherwise.
	isRequiredValidatorConfigured: ((k, v) ->
		notEmptyValidatorIdentifier = 'TYPO3.Flow:NotEmpty'
		if v != undefined
			# set case
			# remove all NotEmptyValidators first
			a = @get('value').filter((validatorConfiguration) -> validatorConfiguration.identifier != notEmptyValidatorIdentifier)
			@set('value', a)

			# then, re-add the validator if needed
			if v == true
				@get('value').push {
					identifier: notEmptyValidatorIdentifier
				}
			@valueChanged()
			# EXTREMELY IMPORTANT that the computed property SETTER returns the given value as well!
			return v
		else
			# get case
			val = !!@get('value').some((validatorConfiguration) -> validatorConfiguration.identifier == notEmptyValidatorIdentifier)
			return val
	).property('value').cacheable()
}

# ***
# ##Class Editor.ValidatorEditor##
#
# This is an editor for all validators. They are defined using the `availableValidators` property.
TYPO3.FormBuilder.View.ElementOptionsPanel.Editor.ValidatorEditor = TYPO3.FormBuilder.View.ElementOptionsPanel.Editor.AbstractCollectionEditor.extend {
	# ###Public Properties###
	# * `availableValidators`: JSON object of available validators, where each validator has the following options:
	#
	#    * `label`: human-readable label of the validator
	#    * `sorting`: sorting index to be used for the validator
	#    * `name`: Validator class name, if not specified the `TYPO3.FormBuilder.View.ElementOptionsPanel.Editor.ValidatorEditor.DefaultValidatorEditor` is used.
	#    * `options`: Validator options to be set (JSON object)
	#    * `required`: (boolean) if TRUE; it is required validator which is not de-selectable
	availableValidators: null,

	# ***
	# ###Private###

	availableCollectionElementsBinding: 'availableValidators'
	templateName: 'ElementOptionsPanel-ValidatorEditor'

	prompt: 'Select a validator to add'

	propertyPath: 'validators'
}

# ***
# ##Class DefaultValidatorEditor##
#
# Base class for validator editors or finisher editors; contains some helper
# methods to be used by subclasses and does not render any editing options.
#
# ###Public API
TYPO3.FormBuilder.View.ElementOptionsPanel.Editor.ValidatorEditor.DefaultValidatorEditor = Ember.View.extend {
	classNames: ['typo3-formbuilder-validator-editor']

	templateName: 'Validator-Default'

	# - `required`: if `true` the editor is automatically added, i.e. we won't show options to remove
	#   the element in this case
	required: false

	# - `collection`: Pointer to the collection which is edited (i.e. the list of validator)
	collection: null

	# - `elementIndex`: index of this validator / finisher
	elementIndex: null

	# - `currentCollectionElement`: Reference to this validator / finisher.
	currentCollectionElement: (->
		@get('collection').get(@get('elementIndex'))
	).property('collection', 'elementIndex').cacheable()

	# - `valueChanged()`: function which needs to be triggered every time the value changed
	valueChanged: Ember.K

	# - `updateCollectionEditorViews()`: function which needs to be triggered when a collection element is added / removed
	updateCollectionEditorViews: Ember.K

	# - `remove()`: call this function to remove this element
	remove: ->
		@get('collection').removeAt(@get('elementIndex'))
		@valueChanged()
		@updateCollectionEditorViews()

	# - `notRequired`: inverse of `required` computed property
	notRequired: (->
		return !@get('required')
	).property('required').cacheable()
}

# ***
# ##Class MinimumMaximumValidatorEditor##
#
# Validator editor which shows a "minimum" and a "maximum field which need
# to be integers.
#
# ###Public API
TYPO3.FormBuilder.View.ElementOptionsPanel.Editor.ValidatorEditor.MinimumMaximumValidatorEditor = TYPO3.FormBuilder.View.ElementOptionsPanel.Editor.ValidatorEditor.DefaultValidatorEditor.extend {
	templateName: 'Validator-MinimumMaximumEditor'

	# - `pathToMinimumOption`: Path to minimum option
	pathToMinimumOption: 'currentCollectionElement.options.minimum'

	# - `pathToMaximumOption`: Path to maximum option
	pathToMaximumOption: 'currentCollectionElement.options.maximum'

	# ***
	# ###Private
	minimum: ((k, v) ->
		if v != undefined
			@setPath(@get('pathToMinimumOption'), v)
			@valueChanged()
			return v
		else
			return @getPath(@get('pathToMinimumOption'))
	).property('pathToMinimumOption').cacheable()

	maximum: ((k, v) ->
		if v != undefined
			@setPath(@get('pathToMaximumOption'), v)
			@valueChanged()
			return v
		else
			return @getPath(@get('pathToMaximumOption'))
	).property('pathToMaximumOption').cacheable()
}

# ***
# ##Class SimpleValueValidatorEditor##
#
# Validator editor which shows a simple input field, by default without
# validations
#
# ###Public API
TYPO3.FormBuilder.View.ElementOptionsPanel.Editor.ValidatorEditor.SimpleValueValidatorEditor = TYPO3.FormBuilder.View.ElementOptionsPanel.Editor.ValidatorEditor.DefaultValidatorEditor.extend {
	templateName: 'Validator-SimpleValueEditor'

	# - `pathToEditedValue`: Path to the edited value of this validator.
	pathToEditedValue: 'currentCollectionElement.options.TODO'

	# - `fieldLabel`: The field label to be shown next to the input field
	fieldLabel: Ember.required()

	# ***
	# ###Private
	value: ((k, v) ->
		if v != undefined
			@setPath(@get('pathToEditedValue'), v)
			@valueChanged()
			return v
		else
			return @getPath(@get('pathToEditedValue'))
	).property('pathToEditedValue').cacheable()
}