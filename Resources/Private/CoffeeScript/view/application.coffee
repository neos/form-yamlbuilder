# <!--
# This file is part of the Neos.Form.YamlBuilder package.
#
# (c) Contributors of the Neos Project - www.neos.io
#
# This package is Open Source Software. For the full copyright and license
# information, please view the LICENSE file which was distributed with this
# source code.
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
Neos.Form.YamlBuilder.View.Application = Ember.View.extend {
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
				paneSelector: '#neos-form-yamlbuilder-header',
				resizable: false,
				spacing_open: 0,
				size: 46,
				minSize: 0
			},
			east: {
				paneSelector:'#neos-form-yamlbuilder-elementOptionsPanel',
				size: 290,
				minSize: 200,
				maxSize: 350
			},
			south: {
				paneSelector: '#neos-form-yamlbuilder-footer',
				resizable: false,
				spacing_open: 0,
				size: 20,
				minSize: 0
			},
			west: {
				paneSelector: '#neos-form-yamlbuilder-elementSidebar',
				size: 240,
				minSize: 200,
				maxSize: 350
			},
			center: {
				paneSelector: '#neos-form-yamlbuilder-stage'
			}
		});
		$('#neos-form-yamlbuilder-elementSidebar').layout({
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
				paneSelector: '#neos-form-yamlbuilder-structurePanel'
			},
			center: {
				paneSelector: '#neos-form-yamlbuilder-insertElementsPanel'
			}
		});
		#$('.neos-form-yamlbuilder').scrollbars({
		#	scrollbarAutohide: false
		#});

	# update <title> when the label of the form definition changes
	updatePageTitle: (->
		document.title = 'Form Builder - ' + Ember.getPath('Neos.Form.YamlBuilder.Model.Form.formDefinition.label')
	).observes('Neos.Form.YamlBuilder.Model.Form.formDefinition.label')
}
