# #Main Base Class#
# Main Entry for the form builder, setting up the environment and initializing
# `TYPO3.FormBuilder` namespace.
#

TYPO3 = window.TYPO3 || {}
window.TYPO3 = TYPO3

window.onbeforeunload = (e) ->
	return undefined unless TYPO3.FormBuilder.Model.Form.get('unsavedContent')

	e = e || window.event

	text = 'There is unsaved content. Are you sure that you want to close the browser?'
	if e
		e.returnValue = text

	return text

# `TYPO3.FormBuilder` is the namespace where the whole package is inside
TYPO3.FormBuilder = Ember.Application.create {
	rootElement: 'body'

	save: ->
		formDefinition = TYPO3.FormBuilder.Utility.convertToSimpleObject(TYPO3.FormBuilder.Model.Form.get('formDefinition'))
		$.post(
			TYPO3.FormBuilder.Configuration.endpoints.saveForm,
			{
				formPersistenceIdentifier: TYPO3.FormBuilder.Configuration?.formPersistenceIdentifier
				formDefinition
			},
			(data, textStatus, jqXHR) =>
				TYPO3.FormBuilder.Model.Form.set('unsavedContent', false)
		)
}
# `TYPO3.FormBuilder.Configuration` contains the server-side generated config array.
TYPO3.FormBuilder.Configuration = window.FORMBUILDER_CONFIGURATION

if TYPO3.FormBuilder.Configuration?.stylesheets
	for stylesheet in TYPO3.FormBuilder.Configuration.stylesheets
		$('head').append($('<link rel="stylesheet" />').attr('href', stylesheet))

if TYPO3.FormBuilder.Configuration?.javaScripts
	for javaScript in TYPO3.FormBuilder.Configuration.javaScripts
		$.getScript(javaScript);

if TYPO3.FormBuilder.Configuration?.formPersistenceIdentifier
	$.getJSON(
		TYPO3.FormBuilder.Configuration.endpoints.loadForm,
		{ formPersistenceIdentifier: TYPO3.FormBuilder.Configuration?.formPersistenceIdentifier },
		(data, textStatus, jqXHR) =>
			TYPO3.FormBuilder.Model.Form.set('formDefinition', TYPO3.FormBuilder.Model.Renderable.create(data))
	)

TYPO3.FormBuilder.Validators = {}
TYPO3.FormBuilder.Validators.isNumberOrBlank = (n) ->
	return true if n == '' or n == null or n == undefined
	return !isNaN(parseFloat(n)) && isFinite(n);


TYPO3.FormBuilder.TextField = Ember.TextField.extend {
	_lastValidValue: false
	validatorName: null

	validate: (v) ->
		if @get('validatorName')
			validator = Ember.getPath(@get('validatorName'))
			return validator.call(this, v)
		return true

	validatedValue: ((k, v) ->
		if arguments.length >= 2
			if @validate(v)
				this._lastValidValue = v

			return this._lastValidValue
		else
			return this._lastValidValue
	).property().cacheable()


	valueBinding: 'validatedValue'
}
