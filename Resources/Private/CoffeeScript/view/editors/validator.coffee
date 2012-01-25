
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