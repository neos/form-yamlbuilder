# #Main Base Class#
# Main Entry point for the form builder, setting up the environment and initializing
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

window.onerror = (errorMessage, url, lineNumber) ->
	alert "There was a JavaScript error in File #{url}, line #{lineNumber}: #{errorMessage}. Please report the error to the developers"
	return false

# `TYPO3.FormBuilder` is the namespace where the whole package is inside
TYPO3.FormBuilder = Ember.Application.create {
	rootElement: 'body'
}

# `TYPO3.FormBuilder.Configuration` contains the server-side generated config array.
TYPO3.FormBuilder.Configuration = window.FORMBUILDER_CONFIGURATION

if TYPO3.FormBuilder.Configuration?.stylesheets
	for stylesheet in TYPO3.FormBuilder.Configuration.stylesheets
		$('head').append($('<link rel="stylesheet" />').attr('href', stylesheet))

if TYPO3.FormBuilder.Configuration?.javaScripts
	for javaScript in TYPO3.FormBuilder.Configuration.javaScripts
		$.getScript(javaScript);

# if the form persistence identifier was configured, we load it using
# the loadForm endpoint
if TYPO3.FormBuilder.Configuration?.formPersistenceIdentifier
	$.getJSON(
		TYPO3.FormBuilder.Configuration.endpoints.loadForm,
		{ formPersistenceIdentifier: TYPO3.FormBuilder.Configuration?.formPersistenceIdentifier },
		(data, textStatus, jqXHR) =>
			TYPO3.FormBuilder.Model.Form.set('formDefinition', TYPO3.FormBuilder.Model.Renderable.create(data))
			TYPO3.FormBuilder.Model.Form.set('unsavedContent', false)
	)


# Definition of some validators which can be used together
# with TYPO3.FormBuilder.View.TextField
TYPO3.FormBuilder.Validators = {}
TYPO3.FormBuilder.Validators.isNumberOrBlank = (n) ->
	return true if n == '' or n == null or n == undefined
	return !isNaN(parseFloat(n)) && isFinite(n);

