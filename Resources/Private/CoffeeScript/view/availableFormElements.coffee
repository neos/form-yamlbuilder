
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
		currentlySelectedRenderable = @get('currentlySelectedElement')
		return unless currentlySelectedRenderable

		newRenderable = TYPO3.FormBuilder.Model.Renderable.create({
			type: @formElementType.get('key')
			label: '',
			identifier: Ember.generateGuid(null, 'formElement')
		})

		if !@formElementType.getPath('formBuilder._isPage') && currentlySelectedRenderable.getPath('typeDefinition.formBuilder._isPage')
			# element to be inserted is no page, but the selected renderable is a page. Thus, we need to add the
			# form element as child.
			currentlySelectedRenderable.get('renderables').pushObject(newRenderable)
		else
			referenceRenderable = currentlySelectedRenderable
			if @formElementType.getPath('formBuilder._isPage') && !currentlySelectedRenderable.getPath('typeDefinition.formBuilder._isPage')
				# element to be inserted IS a page, but the selected renderable is not. thus, we need to bubble up the tree
				# to find the closest page.
				referenceRenderable = referenceRenderable.findEnclosingPage()

			parentRenderablesArray = referenceRenderable.getPath('parentRenderable.renderables')
			indexInParent = parentRenderablesArray.indexOf(referenceRenderable)
			parentRenderablesArray.replace(indexInParent+1, 0, [newRenderable])

		@set('currentlySelectedElement', newRenderable)
}