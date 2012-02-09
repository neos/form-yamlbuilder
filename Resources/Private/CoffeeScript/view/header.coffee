TYPO3.FormBuilder.View.Header = Ember.View.extend {
	templateName: 'Header'
}

TYPO3.FormBuilder.View.Header.PresetSelector = Ember.View.extend {
# TODO
	tagName: 'a'
}

TYPO3.FormBuilder.View.Header.PreviewButton = Ember.Button.extend {
# TODO
}


TYPO3.FormBuilder.View.Header.SaveButton = Ember.Button.extend {
	targetObject: (-> return this).property().cacheable()
	action: ->
		@save()

	classNames: ['typo3-formbuilder-savebutton']
	classNameBindings: ['isActive', 'currentStatus'],

	currentStatus: ''

	save: ->
		@set('currentStatus', 'currently-saving')
		formDefinition = TYPO3.FormBuilder.Utility.convertToSimpleObject(TYPO3.FormBuilder.Model.Form.get('formDefinition'))

		$.post(
			TYPO3.FormBuilder.Configuration.endpoints.saveForm,
			{
				formPersistenceIdentifier: TYPO3.FormBuilder.Configuration?.formPersistenceIdentifier
				formDefinition
			},
			(data, textStatus, jqXHR) =>
				if data == 'success'
					@set('currentStatus', 'saved')
					TYPO3.FormBuilder.Model.Form.set('unsavedContent', false)
				else
					@set('currentStatus', 'save-error')
		)
}