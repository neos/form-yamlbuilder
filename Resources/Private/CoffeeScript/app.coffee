# <!--
# This file is part of the Neos.Form.YamlBuilder package.
#
# (c) Contributors of the Neos Project - www.neos.io
#
# This package is Open Source Software. For the full copyright and license
# information, please view the LICENSE file which was distributed with this
# source code.
# -->


# #Main Base Class#
# Main Entry point for the form builder, setting up the environment and initializing
# `Neos.Form.YamlBuilder` namespace.
#

Neos = window.Neos || {}
window.Neos = Neos
Neos.Form = Neos.Form || {}

window.onbeforeunload = (e) ->
	return undefined unless Neos.Form.YamlBuilder.Model.Form.get('unsavedContent')
	e = e || window.event
	text = 'There is unsaved content. Are you sure that you want to close the browser?'
	if e
		e.returnValue = text
	return text

window.onerror = (errorMessage, url, lineNumber) ->
	alert "There was a JavaScript error in File #{url}, line #{lineNumber}: #{errorMessage}. Please report the error to the developers"
	return false

# `Neos.Form.YamlBuilder` is the namespace where the whole package is inside
Neos.Form.YamlBuilder = Ember.Application.create {
	rootElement: 'body'
}

# `Neos.Form.YamlBuilder.Configuration` contains the server-side generated config array.
Neos.Form.YamlBuilder.Configuration = window.NEOS_FORM_YAMLBUILDER_CONFIGURATION

if Neos.Form.YamlBuilder.Configuration?.stylesheets
	for stylesheet in Neos.Form.YamlBuilder.Configuration.stylesheets
		$('head').append($('<link rel="stylesheet" />').attr('href', stylesheet))

if Neos.Form.YamlBuilder.Configuration?.javaScripts
	for javaScript in Neos.Form.YamlBuilder.Configuration.javaScripts
		$.getScript(javaScript);

# if the form persistence identifier was configured, we load it using
# the loadForm endpoint
if Neos.Form.YamlBuilder.Configuration?.formPersistenceIdentifier
	$.getJSON(
		Neos.Form.YamlBuilder.Configuration.endpoints.loadForm,
		{ formPersistenceIdentifier: Neos.Form.YamlBuilder.Configuration?.formPersistenceIdentifier },
		(data, textStatus, jqXHR) =>
			Neos.Form.YamlBuilder.Model.Form.set('formDefinition', Neos.Form.YamlBuilder.Model.Renderable.create(data))
			Neos.Form.YamlBuilder.Model.Form.set('unsavedContent', false)
	)


# Definition of some validators which can be used together
# with Neos.Form.YamlBuilder.View.TextField
Neos.Form.YamlBuilder.Validators = {}
Neos.Form.YamlBuilder.Validators.isNumberOrBlank = (n) ->
	return true if n == '' or n == null or n == undefined
	return !isNaN(parseFloat(n)) && isFinite(n);

