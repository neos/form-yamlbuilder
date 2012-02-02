# #Namespace `TYPO3.FormBuilder.View`#
#
# All views in this file render the grouped list of available form elements on
# the bottom-left of the Form Builder.
#
# Contains the following classes:
#
# * AvailableFormElementsView
# * AvailableFormElementsElement
#
# ***
# ##Class View.AvailableFormElementsView##
#
# Outer view which renders the available form elements. It especially groups the
# form elements by the specified "group", converting the flat array into a hierarchy,
# where the first level is the group, and the second level the form element types
# belonging to this group.
#
# This also evaluates the *sorting* property and orders the form elements and groups
# in the respective order.
TYPO3.FormBuilder.View.AvailableFormElementsView = Ember.View.extend {
	# ***
	# ###Private###
	classNames: ['availableFormElements']
	templateName: 'AvailableFormElements'
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
}

# ***
# ##Class View.AvailableFormElementsElement##
#
# This view class implements a single `<li>` element for a specific form element
# type, and actually adds the element to the form when clicking on it.
#
# When an element is added, the following code is executed:
#
# - build a new `TYPO3.FormBuilder.Model.Renderable` object, using the specified type
#   and a random identifier.
# - Further, apply the default values `label, defaultValue, properties` and `renderingOptions`
#   from the form type definition, such that the values can be edited correctly
# - Third, find the currently selected renderable, and depending on this, insert the new
#   renderable before/after/inside the currently selected renderable. See below for details.
# - Make the newly inserted renderable active.
#
# ###Insertion Position###
#
# The logic for determining the insertion position works as follows:
#
# - If a *page* should be inserted, it is inserted *after the currently selected page*. If we
#   have a form element selected, we take the page this form element belongs to and add the new
#   page after it.
# - Normal form elements are, by default, added *after* the currently selected form element.
#   However, if a *page* is selected, it is added as the *child* of this page.
TYPO3.FormBuilder.View.AvailableFormElementsElement = Ember.View.extend {
	# ***
	# ###Private###
	currentlySelectedElementBinding: 'TYPO3.FormBuilder.Model.Form.currentlySelectedRenderable'
	# this is set from the outside, containing a reference to the enclosing form element type.
	content: null

	formElementTypeBinding: 'content'

	# set the label and title attributes after we are inserted into the DOM
	didInsertElement: ->
		@$().html(@getPath('formElementType.formBuilder.label'))
		@$().attr('title', @getPath('formElementType.key'))
		@$().addClass(@getPath('formElementType.__cssClassNames'))

	classNameBindings: ['enabled:formbuilder-enabled']

	# the editable is disabled, if it is no top level element and if a page is selected which is not _compositeRenderable
	enabled: (->
		if @getPath('formElementType.formBuilder._isTopLevel')
			# we are a top level element, and thus are never disabled
			return true

		# we are no toplevel element
		currentlySelectedRenderable = @get('currentlySelectedElement')
		return false unless currentlySelectedRenderable

		if currentlySelectedRenderable.getPath('typeDefinition.formBuilder._isTopLevel') && !currentlySelectedRenderable.getPath('typeDefinition.formBuilder._isCompositeRenderable')
			# the currently selected renderable IS a top level renderable, and NO composite renderable.
			# thus, we are not allowed to render anything here
			return false

		return true
	).property('formElementType', 'currentlySelectedElement').cacheable()

	# callback which is triggered when clicking on an element. Determines the insertion position and
	# adds the new element.
	click: ->
		currentlySelectedRenderable = @get('currentlySelectedElement')
		return unless currentlySelectedRenderable
		return unless @get('enabled')

		defaultValues = @getPath('formElementType.formBuilder.predefinedDefaults') || {}

		newRenderable = TYPO3.FormBuilder.Model.Renderable.create($.extend({
			type: @getPath('formElementType.key')
			identifier: Ember.generateGuid(null, 'formElement')
		}, defaultValues))

		if !@getPath('formElementType.formBuilder._isTopLevel') && currentlySelectedRenderable.getPath('typeDefinition.formBuilder._isCompositeRenderable')
			# element to be inserted is no toplevel object (i.e. no page), but the selected renderable is a composite element (a page or section). Thus, we need to add the
			# form element as child.
			currentlySelectedRenderable.get('renderables').pushObject(newRenderable)
		else
			referenceRenderable = currentlySelectedRenderable
			if referenceRenderable == TYPO3.FormBuilder.Model.Form.get('formDefinition')
				# currently selected renderable is the form definition itself -> select first page
				referenceRenderable = referenceRenderable.getPath('renderables.0')
			else if @getPath('formElementType.formBuilder._isTopLevel') && !currentlySelectedRenderable.getPath('typeDefinition.formBuilder._isTopLevel')
				# element to be inserted IS a page, but the selected renderable is not a top level element. thus, we need to bubble up the tree
				# to find the closest page.
				referenceRenderable = referenceRenderable.findEnclosingPage()

			parentRenderablesArray = referenceRenderable.getPath('parentRenderable.renderables')
			indexInParent = parentRenderablesArray.indexOf(referenceRenderable)
			parentRenderablesArray.replace(indexInParent+1, 0, [newRenderable])

		@set('currentlySelectedElement', newRenderable)
}

TYPO3.FormBuilder.View.AvailableFormElementsCollection = Ember.CollectionView.extend {
	itemViewClass: TYPO3.FormBuilder.View.AvailableFormElementsElement
}