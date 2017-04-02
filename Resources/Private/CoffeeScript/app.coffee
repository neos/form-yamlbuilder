# <!--
# This script belongs to the TYPO3 Flow package "Neos.FormBuilder".
#
# It is free software; you can redistribute it and/or modify it under
# the terms of the GNU Lesser General Public License, either version 3
#  of the License, or (at your option) any later version.
#
# The TYPO3 project - inspiring people to share!
# -->


# #Main Base Class#
# Main Entry point for the form builder, setting up the environment and initializing
# `Neos.FormBuilder` namespace.
#

TYPO3 = window.TYPO3 || {}
window.TYPO3 = TYPO3

window.onbeforeunload = (e) ->
	return undefined unless Neos.FormBuilder.Model.Form.get('unsavedContent')
	e = e || window.event
	text = 'There is unsaved content. Are you sure that you want to close the browser?'
	if e
		e.returnValue = text
	return text

window.onerror = (errorMessage, url, lineNumber) ->
	alert "There was a JavaScript error in File #{url}, line #{lineNumber}: #{errorMessage}. Please report the error to the developers"
	return false

# `Neos.FormBuilder` is the namespace where the whole package is inside
Neos.FormBuilder = Ember.Application.create {
	rootElement: 'body'
}

# `Neos.FormBuilder.Configuration` contains the server-side generated config array.
Neos.FormBuilder.Configuration = window.FORMBUILDER_CONFIGURATION

if Neos.FormBuilder.Configuration?.stylesheets
	for stylesheet in Neos.FormBuilder.Configuration.stylesheets
		$('head').append($('<link rel="stylesheet" />').attr('href', stylesheet))

if Neos.FormBuilder.Configuration?.javaScripts
	for javaScript in Neos.FormBuilder.Configuration.javaScripts
		$.getScript(javaScript);

# if the form persistence identifier was configured, we load it using
# the loadForm endpoint
if Neos.FormBuilder.Configuration?.formPersistenceIdentifier
	$.getJSON(
		Neos.FormBuilder.Configuration.endpoints.loadForm,
		{ formPersistenceIdentifier: Neos.FormBuilder.Configuration?.formPersistenceIdentifier },
		(data, textStatus, jqXHR) =>
			Neos.FormBuilder.Model.Form.set('formDefinition', Neos.FormBuilder.Model.Renderable.create(data))
			Neos.FormBuilder.Model.Form.set('unsavedContent', false)
	)


# Definition of some validators which can be used together
# with Neos.FormBuilder.View.TextField
Neos.FormBuilder.Validators = {}
Neos.FormBuilder.Validators.isNumberOrBlank = (n) ->
	return true if n == '' or n == null or n == undefined
	return !isNaN(parseFloat(n)) && isFinite(n);

