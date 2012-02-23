# <!--
# This script belongs to the FLOW3 package "TYPO3.FormBuilder".
#
# It is free software; you can redistribute it and/or modify it under
# the terms of the GNU Lesser General Public License, either version 3
#  of the License, or (at your option) any later version.
#
# The TYPO3 project - inspiring people to share!
# -->


# ***
# ##Class View.Application##
#
# This view is the main *application*, controlling the overal layout of the
# form builder.
#
# It mainly uses the jQuery layout() plugin for this.
# ***
# ###Private###
TYPO3.FormBuilder.View.Application = Ember.View.extend {
	templateName: 'Application'
	didInsertElement: ->
		@addLayout()
	addLayout: ->
		# Build the layout as stated
		$('body').layout({
			defaults: {
				minSize: 100,
				spacing_open: 3,
				closable: false,
				slidable: false,
				resizable: true,
				useStateCookie: false
			},
			north: {
				paneSelector: '#typo3-formbuilder-header',
				resizable: false,
				spacing_open: 0,
				size: 46,
				minSize: 0
			},
			east: {
				paneSelector:'#typo3-formbuilder-elementOptionsPanel',
				size: 290,
				minSize: 200,
				maxSize: 350
			},
			south: {
				paneSelector: '#typo3-formbuilder-footer',
				resizable: false,
				spacing_open: 0,
				size: 20,
				minSize: 0
			},
			west: {
				paneSelector: '#typo3-formbuilder-elementSidebar',
				size: 240,
				minSize: 200,
				maxSize: 350
			},
			center: {
				paneSelector: '#typo3-formbuilder-stage'
			}
		});
		$('#typo3-formbuilder-elementSidebar').layout({
			defaults: {
				minSize: 100,
				closable: false,
				slidable: false,
				resizable: true,
				spacing_open: 5,
				useStateCookie: true
			},
			north: {
				minSize: 100,
				size: 300,
				paneSelector: '#typo3-formbuilder-structurePanel'
			},
			center: {
				paneSelector: '#typo3-formbuilder-insertElementsPanel'
			}
		});
		#$('.typo3-formbuilder').scrollbars({
		#	scrollbarAutohide: false
		#});

	# update <title> when the label of the form definition changes
	updatePageTitle: (->
		document.title = 'Form Builder - ' + Ember.getPath('TYPO3.FormBuilder.Model.Form.formDefinition.label')
	).observes('TYPO3.FormBuilder.Model.Form.formDefinition.label')
}