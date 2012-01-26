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
		notEmptyValidatorClassName = 'TYPO3\\FLOW3\\Validation\\Validator\\NotEmptyValidator'
		if v != undefined
			# set case
			# remove all NotEmptyValidators first
			a = @get('value').filter((validatorConfiguration) -> validatorConfiguration.name != notEmptyValidatorClassName)
			@set('value', a)

			# then, re-add the validator if needed
			if v == true
				@get('value').push {
					name: notEmptyValidatorClassName
				}
			@valueChanged()
			# EXTREMELY IMPORTANT that the computed property SETTER returns the given value as well!
			return v
		else
			# get case
			val = !!@get('value').some((validatorConfiguration) -> validatorConfiguration.name == notEmptyValidatorClassName)
			return val
	).property('value').cacheable()
}

# ***
# ##Class Editor.ValidatorEditor##
#
# This is an editor for all validators. They are defined using the `availableValidators` property.
TYPO3.FormBuilder.View.Editor.ValidatorEditor = TYPO3.FormBuilder.View.Editor.AbstractPropertyEditor.extend {
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
	templateName: 'ValidatorEditor'
	propertyPath: 'validators'
	defaultValue: (-> []).property().cacheable()

	# list of initialized views, one for each validator editor
	validatorEditorViews: null

	# initializer.
	init: ->
		@_super()
		@validatorEditorViews = []
		@updateValidatorEditorViews()

	# sort the available validators based on their sorting
	sortedAvailableValidators: (->
		validatorsArray = []
		for key, validatorTemplate of @get('availableValidators')
			continue if @isValidatorTemplateFoundInValidatorList(validatorTemplate)
			validatorsArray.push($.extend({key}, validatorTemplate))
		validatorsArray.sort((a, b) -> a.sorting - b.sorting)
		return validatorsArray
	).property('availableValidators', 'formElement.__nestedPropertyChange').cacheable()

	# if TRUE, no validators are available.
	noValidatorsAvailable: ( ->
		@get('sortedAvailableValidators').length == 0
	).property('sortedAvailableValidators').cacheable()

	# this property needs to be bound to the current selection, of the "add validator"
	# select field, such that we can observe this value for changes.
	addValidatorSelection: null

	# helper function which adds a new validator
	addValidator: (->
		validatorToBeAdded = @get('addValidatorSelection')
		return unless validatorToBeAdded

		@get('value').push {
			name: validatorToBeAdded.name
			options: validatorToBeAdded.options
		}

		@valueChanged()
		@updateValidatorEditorViews()

		# reset the "add validator" dropdown
		@set('addValidatorSelection', null)
	).observes('addValidatorSelection')

	# helper function which updates the validator editor views.
	updateValidatorEditorViews: (->
		@addRequiredValidatorsIfNeededToValidatorList()

		validators = @get('value')
		availableValidators = @get('availableValidators')

		validatorViews = []

		for validator, i in validators
			for key, validatorTemplate of availableValidators
				if validatorTemplate.name == validator.name # TODO: also check options of validator!
					# we found the correct validatorTemplate for the current validator,
					# thus we can output label and determine the view to be used.
					validatorEditor = Ember.getPath(validatorTemplate.viewName || 'TYPO3.FormBuilder.View.Editor.ValidatorEditor.DefaultValidatorEditor')
					throw "Validator Editor class '#{validatorTemplate.viewName}' not found" if !validatorEditor
					validatorEditorOptions = $.extend({
						validatorIndex: i
						valueChanged: =>
							@valueChanged()
						updateValidatorEditorViews: =>
							@updateValidatorEditorViews()
						validators: @get('value')
					}, validatorTemplate)
					validatorViews.push(validatorEditor.create(validatorEditorOptions))
					break

		@set('validatorEditorViews', validatorViews)
	).observes('value')

	# add the required validators if needed to the list of validators
	addRequiredValidatorsIfNeededToValidatorList: ->
		validators = @get('value')
		availableValidators = @get('availableValidators')

		requiredAndMissingValidators = []

		for key, validatorTemplate of availableValidators
			continue unless validatorTemplate.required # continue if validator template is not required

			if !@isValidatorTemplateFoundInValidatorList(validatorTemplate)
				requiredAndMissingValidators.push(key)

		for validatorTemplateName in requiredAndMissingValidators
			validators.push({
				name: availableValidators[validatorTemplateName].name
				options: $.extend({}, availableValidators[validatorTemplateName].options)
			})

	# is a validator template found in the list of validators?
	isValidatorTemplateFoundInValidatorList: (validatorTemplate) ->
		validators = @get('value')
		for validator in validators
			if validatorTemplate.name == validator.name # TODO: also check options of validator!
				return true

		return false
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
	validators: null

	# index of this validator
	validatorIndex: null

	validator: (->
		@get('validators').get(@get('validatorIndex'))
	).property('validators', 'validatorIndex')

	valueChanged: Ember.K

	notRequired: (->
		return !@get('required')
	).property('required').cacheable()

	remove: ->
		@get('validators').removeAt(@get('validatorIndex'))
		@valueChanged()
		@updateValidatorEditorViews()
}

TYPO3.FormBuilder.View.Editor.ValidatorEditor.MinimumMaximumValidatorEditor = TYPO3.FormBuilder.View.Editor.ValidatorEditor.DefaultValidatorEditor.extend {
	templateName: 'ValidatorEditor-MinimumMaximum'

	pathToMinimumOption: 'validator.options.minimum'

	pathToMaximumOption: 'validator.options.maximum'


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