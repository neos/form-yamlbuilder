
TYPO3.FormBuilder.View.AvailableFormElementsView = Ember.View.extend {
	classNames: ['availableFormElements']
	allFormElementTypesBinding: 'TYPO3.FormBuilder.Model.FormElementTypes.allTypeNames'

	formElementsGrouped: (->
		formElementsByGroup = {}

		for formElementTypeName in @get('allFormElementTypes')
			formElementType = TYPO3.FormBuilder.Model.FormElementTypes.get(formElementTypeName)
			continue unless formElementType.formBuilder?.group?
			if !formElementsByGroup[formElementType.formBuilder.group]
				formElementsByGroup[formElementType.formBuilder.group] = []

			formElementType.set('key', formElementTypeName)
			formElementsByGroup[formElementType.formBuilder.group].push(formElementType)

		formGroups = []
		for formGroupName in TYPO3.FormBuilder.Model.FormElementGroups.get('allGroupNames')
			formGroup = TYPO3.FormBuilder.Model.FormElementGroups.get(formGroupName)
			formGroup.set('key', formGroupName)
			formElementsByGroup[formGroupName]?.sort((a, b) -> a.formBuilder.sorting - b.formBuilder.sorting)
			formGroup.set('elements', formElementsByGroup[formGroupName])
			formGroups.push(formGroup)

		formGroups.sort((a, b) -> a.sorting - b.sorting)

		return formGroups
	).property('allFormElementTypes').cacheable()

	templateName: 'AvailableFormElements'
}

TYPO3.FormBuilder.View.AvailableFormElementsElement = Ember.View.extend {
	tagName: 'li',
	formElementType: null
	currentlySelectedElementBinding: 'TYPO3.FormBuilder.Model.Form.currentlySelectedRenderable'

	didInsertElement: ->
		@$().html(@getPath('formElementType.formBuilder.label'))
		@$().attr('title', @getPath('formElementType.key'))
	click: ->
		el = @get('currentlySelectedElement')
		return unless el

		parentRenderablesArray = el.getPath('parentRenderable.renderables')
		indexInParent = parentRenderablesArray.indexOf(el)

		newRenderable = TYPO3.FormBuilder.Model.Renderable.create({
			type: @formElementType.get('key')
			label: '',
			identifier: Ember.generateGuid(null, 'formElement')
		})

		parentRenderablesArray.replace(indexInParent+1, 0, [newRenderable])

		@set('currentlySelectedElement', newRenderable)
}