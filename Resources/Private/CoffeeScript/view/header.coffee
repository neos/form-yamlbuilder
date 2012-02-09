# #Namespace `TYPO3.FormBuilder.View.Header`#
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
TYPO3.FormBuilder.View.Header = Ember.View.extend {
	templateName: 'Header'
}

# ***
# ###Private
# ####Preset Selector
TYPO3.FormBuilder.View.Header.PresetSelector = Ember.Select.extend {
	contentBinding: 'TYPO3.FormBuilder.Configuration.availablePresets'
	optionLabelPath: 'content.title'
	init: ->
		@resetSelection()
		return @_super.apply(this, arguments)
	reloadIfPresetChanged: (->
		return if @getPath('selection.name') == TYPO3.FormBuilder.Configuration.presetName

		if TYPO3.FormBuilder.Model.Form.get('unsavedContent')
			that = this
			$('<div>There are unsaved changes, but you need to save before changing the preset. Do you want to save now?</div>').dialog {
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
			if val.name == TYPO3.FormBuilder.Configuration.presetName
				@set('selection', val)
				break
	).observes('content')

	saveAndRedirect: ->
		TYPO3.FormBuilder.Model.Form.save( (success)=>
			@redirect() if success
		)

	redirect: ->
		window.location.href = TYPO3.FormBuilder.Configuration.endpoints.editForm + "?formPersistenceIdentifier=#{encodeURIComponent(TYPO3.FormBuilder.Configuration.formPersistenceIdentifier)}&presetName=#{encodeURIComponent(@getPath('selection.name'))}"
}

# ####Preview Button
TYPO3.FormBuilder.View.Header.PreviewButton = Ember.Button.extend {
# TODO
}

# ####Save Button
TYPO3.FormBuilder.View.Header.SaveButton = Ember.Button.extend {
	targetObject: (-> return this).property().cacheable()
	action: ->
		@save()

	classNames: ['typo3-formbuilder-savebutton']
	classNameBindings: ['isActive', 'currentStatus'],

	currentStatusBinding: 'TYPO3.FormBuilder.Model.Form.saveStatus'

	save: ->
		TYPO3.FormBuilder.Model.Form.save()
}