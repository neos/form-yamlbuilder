
TYPO3.FormBuilder.View.Editor.RequiredValidatorEditor = TYPO3.FormBuilder.View.Editor.AbstractPropertyEditor.extend {
	### PUBLIC API ###

	### PRIVATE ###
	templateName: 'RequiredValidatorEditor'

	propertyPath: 'validators'
	defaultValue: (-> []).property().cacheable()

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

TYPO3.FormBuilder.View.Editor.ValidatorEditor = TYPO3.FormBuilder.View.Editor.AbstractPropertyEditor.extend {
	# ###Public###
	# * `availableValidators`: JSON object of available validators, where each validator has the following options:
	#
	#    * `label`: human-readable label of the validator
	#    * `sorting`: sorting index to be used for the validator
	#    * `name`: Validator class name
	#    * `options`: Validator options to be set (JSON object)
	#    * `required`: (boolean) if TRUE; it is required validator
	availableValidators: null,

	# ***
	# ###Private###
	templateName: 'ValidatorEditor'

	propertyPath: 'validators'
	defaultValue: (-> []).property().cacheable()

	init: ->
		@_super()
		@updateValidatorEditorViews()

	sortedAvailableValidators: (->
		validatorsArray = []
		for key, validatorTemplate of @get('availableValidators')
			continue if @isValidatorTemplateFoundInValidatorList(validatorTemplate) # TODO: this does not yet work for added validators
			validatorsArray.push($.extend({key}, validatorTemplate))
		validatorsArray.sort((a, b) -> a.sorting - b.sorting)
		return validatorsArray
	).property('availableValidators', 'formElement.__nestedPropertyChange').cacheable()

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

	validatorEditorViews: null

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
							@updateValidatorEditorViews()
						validators: @get('value')
					}, validatorTemplate)
					validatorViews.push(validatorEditor.create(validatorEditorOptions))
					break

		@set('validatorEditorViews', validatorViews)
	).observes('value', 'availableValidators')

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

	isValidatorTemplateFoundInValidatorList: (validatorTemplate) ->
		validators = @get('value')
		for validator in validators
			if validatorTemplate.name == validator.name # TODO: also check options of validator!
				return true

		return false
}

TYPO3.FormBuilder.View.Editor.ValidatorEditor.DefaultValidatorEditor = Ember.View.extend {
	classNames: ['formbuilder-validator-editor']
	templateName: 'ValidatorEditor-Default'

	required: false

	# array of validators
	validators: null

	# index of this validator
	validatorIndex: null

	valueChanged: Ember.K

	notRequired: (->
		return !@get('required')
	).property('required').cacheable()

	remove: ->
		@get('validators').removeAt(@get('validatorIndex'))
		@valueChanged()
}