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
TYPO3.FormBuilder.View.Editor.RequiredValidatorEditor = TYPO3.FormBuilder.View.Editor.AbstractPropertyEditor.extend {
	# ***
	# ###Private###
	templateName: 'RequiredValidatorEditor'
	propertyPath: 'validators'
	defaultValue: (-> []).property().cacheable()

	# returns TRUE if the required validator is currently configured, FALSE otherwise.
	isRequiredValidatorConfigured: ((k, v) ->
		notEmptyValidatorIdentifier = 'TYPO3.FLOW3:NotEmpty'
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
TYPO3.FormBuilder.View.Editor.ValidatorEditor = TYPO3.FormBuilder.View.Editor.AbstractCollectionEditor.extend {
	# ###Public Properties###
	# * `availableValidators`: JSON object of available validators, where each validator has the following options:
	#
	#    * `label`: human-readable label of the validator
	#    * `sorting`: sorting index to be used for the validator
	#    * `name`: Validator class name, if not specified the `TYPO3.FormBuilder.View.Editor.ValidatorEditor.DefaultValidatorEditor` is used.
	#    * `options`: Validator options to be set (JSON object)
	#    * `required`: (boolean) if TRUE; it is required validator which is not de-selectable
	availableValidators: null,

	# ***
	# ###Private###

	availableCollectionElementsBinding: 'availableValidators'
	templateName: 'ValidatorEditor'

	prompt: 'Select a validator to add'

	propertyPath: 'validators'
}

# ***
# ##Class Editor.ValidatorEditor.DefaultValidatorEditor##
#
# Base class for validator editors.
# TODO: continue documentation here
TYPO3.FormBuilder.View.Editor.ValidatorEditor.DefaultValidatorEditor = Ember.View.extend {
	classNames: ['formbuilder-validator-editor']
	templateName: 'ValidatorEditor-Default'

	required: false

	# array of validators
	collection: null

	# index of this validator
	elementIndex: null

	currentCollectionElement: (->
		@get('collection').get(@get('elementIndex'))
	).property('collection', 'elementIndex').cacheable()

	valueChanged: Ember.K
	updateCollectionEditorViews: Ember.K

	notRequired: (->
		return !@get('required')
	).property('required').cacheable()

	remove: ->
		@get('collection').removeAt(@get('elementIndex'))
		@valueChanged()
		@updateCollectionEditorViews()
}

TYPO3.FormBuilder.View.Editor.ValidatorEditor.MinimumMaximumValidatorEditor = TYPO3.FormBuilder.View.Editor.ValidatorEditor.DefaultValidatorEditor.extend {
	templateName: 'ValidatorEditor-MinimumMaximum'

	pathToMinimumOption: 'currentCollectionElement.options.minimum'

	pathToMaximumOption: 'currentCollectionElement.options.maximum'

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

TYPO3.FormBuilder.View.Editor.ValidatorEditor.SimpleValueValidatorEditor = TYPO3.FormBuilder.View.Editor.ValidatorEditor.DefaultValidatorEditor.extend {
	templateName: 'ValidatorEditor-SimpleValue'

	# this needs to be filled by the parent
	pathToEditedValue: 'currentCollectionElement.options.TODO'

	fieldLabel: Ember.required()

	value: ((k, v) ->
		if v != undefined
			@setPath(@get('pathToEditedValue'), v)
			@valueChanged()
			return v
		else
			return @getPath(@get('pathToEditedValue'))
	).property('pathToEditedValue').cacheable()
}