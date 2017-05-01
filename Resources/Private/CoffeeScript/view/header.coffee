# <!--
# This file is part of the Neos.Formbuilder package.
#
# (c) Contributors of the Neos Project - www.neos.io
#
# This package is Open Source Software. For the full copyright and license
# information, please view the LICENSE file which was distributed with this
# source code.
# -->


# #Namespace `Neos.FormBuilder.View.Header`#
#
# All views in this file help rendering the header area of the Form Builder
#
# Contains the following classes:
#
# * Header
# * Header.PresetSelector
# * Header.PreviewButton
# * Header.SaveButton
#
# ***
# ##Class View.Header##
# Header View.
Neos.FormBuilder.View.Header = Ember.View.extend {
	templateName: 'Header'
}

# ***
# ###Private
# ####Preset Selector
Neos.FormBuilder.View.Header.PresetSelector = Ember.Select.extend {
	contentBinding: 'Neos.FormBuilder.Configuration.availablePresets'
	optionLabelPath: 'content.title'
	init: ->
		@resetSelection()
		return @_super.apply(this, arguments)
	reloadIfPresetChanged: (->
		return if @getPath('selection.name') == Neos.FormBuilder.Configuration.presetName

		if Neos.FormBuilder.Model.Form.get('unsavedContent')
			that = this
			$('<div>There are unsaved changes, but you need to save before changing the preset. Do you want to save now?</div>').dialog {
				dialogClass: 'neos-formbuilder-dialog',
				title: 'Save changes?',
				modal: true
				resizable: false
				buttons: {
					'Save and redirect': ->
						that.saveAndRedirect()
						$(this).dialog('close')
					'Cancel': ->
						# here, we need to restore the old selection
						that.resetSelection()
						$(this).dialog('close')
				}
			}
		else
			@redirect()
	).observes('selection')

	resetSelection: (->
		return unless @get('content')
		for val in @get('content')
			if val.name == Neos.FormBuilder.Configuration.presetName
				@set('selection', val)
				break
	).observes('content')

	saveAndRedirect: ->
		Neos.FormBuilder.Model.Form.save( (success)=>
			@redirect() if success
		)

	redirect: ->
		window.location.href = Neos.FormBuilder.Utility.getUri(Neos.FormBuilder.Configuration.endpoints.editForm, @getPath('selection.name'))
}

# ####Preview Button
Neos.FormBuilder.View.Header.PreviewButton = Ember.Button.extend {
	targetObject: (-> return this).property().cacheable()
	action: ->
		@preview()

	preview: ->
		windowIdentifier = 'preview_' + Neos.FormBuilder.Model.Form.getPath('formDefinition.identifier')
		# IE HACK: to make the preview work in IE8, we need to prepend a "/" in front of the URI
		window.open('/' + Neos.FormBuilder.Utility.getUri(Neos.FormBuilder.Configuration.endpoints.previewForm), windowIdentifier)
}

# ####Save Button
Neos.FormBuilder.View.Header.SaveButton = Ember.Button.extend {
	targetObject: (-> return this).property().cacheable()
	action: ->
		@save()

	classNames: ['neos-formbuilder-savebutton']
	classNameBindings: ['isActive', 'currentStatus'],

	currentStatusBinding: 'Neos.FormBuilder.Model.Form.saveStatus'
	disabled: (->
		return !Ember.getPath('Neos.FormBuilder.Model.Form.unsavedContent')
	).property('Neos.FormBuilder.Model.Form.unsavedContent').cacheable()

	save: ->
		Neos.FormBuilder.Model.Form.save()
}
