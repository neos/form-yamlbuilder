# #Main Base Class#
# Main Entry for the form builder, setting up the environment and initializing
# `TYPO3.FormBuilder` namespace.
#

TYPO3 = window.TYPO3 || {}
window.TYPO3 = TYPO3

# `TYPO3.FormBuilder` is the namespace where the whole package is inside
TYPO3.FormBuilder = Ember.Application.create {
	rootElement: 'body'
	save: ->
		console.log("Save clicked")

		formDefinition = TYPO3.FormBuilder.Utility.convertToSimpleObject(TYPO3.FormBuilder.Model.Form.get('formDefinition'))
		$.post(
			TYPO3.FormBuilder.Configuration.endpoints.saveForm,
			{
				formPersistenceIdentifier: TYPO3.FormBuilder.Configuration?.formPersistenceIdentifier
				formDefinition
			},
			(data, textStatus, jqXHR) =>
				console.log("SAVED")
		)
}
# `TYPO3.FormBuilder.Configuration` contains the server-side generated config array.
TYPO3.FormBuilder.Configuration = window.FORMBUILDER_CONFIGURATION

if TYPO3.FormBuilder.Configuration?.cssFiles
	for cssFile in TYPO3.FormBuilder.Configuration.cssFiles
		$('head').append($('<link rel="stylesheet" />').attr('href', cssFile))

if TYPO3.FormBuilder.Configuration?.formPersistenceIdentifier
	$.getJSON(
		TYPO3.FormBuilder.Configuration.endpoints.loadForm,
		{ formPersistenceIdentifier: TYPO3.FormBuilder.Configuration?.formPersistenceIdentifier },
		(data, textStatus, jqXHR) =>
			TYPO3.FormBuilder.Model.Form.set('formDefinition', TYPO3.FormBuilder.Model.Renderable.create(data))
	)
