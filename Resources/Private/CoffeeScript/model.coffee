# #Namespace `TYPO3.FormBuilder.Model`#

# Contains the following classes:
#
# * Form *Singleton*
# * Renderable
# * FormElementType
# * FormElementTypes *Singleton*
# * FormElementGroups *Singleton*

TYPO3.FormBuilder.Model = {};

# ***
# ##Model.Form##
#
# **Singleton**
#
# Container which has a reference to the currently edited form definition and
# to the currently selected renderable.
TYPO3.FormBuilder.Model.Form = Ember.Object.create {
	# ###Public Properties###
	# * `formDefinition`: Reference to the `Renderable` object for the form.
	formDefinition: null,

	# * `unsavedContent`: if TRUE, has unsaved content. FALSE otherwise.
	unsavedContent: false,

	# * `currentlySelectedRenderable`: Reference to the currently selected `Renderable` object.
	currentlySelectedRenderable: null

	# * `saveStatus`: one of "" (never saved before), "currently-saving" (save currently being done), "saved" (last save successful) and "save-error" (last save error). Read-only!
	saveStatus: ''

	# * `save(callback)`: Save this form; and when save is complete, trigger callback
	save: (callback = null) ->
		@set('saveStatus', 'currently-saving')
		formDefinition = TYPO3.FormBuilder.Utility.convertToSimpleObject(@get('formDefinition'))

		$.post(
			TYPO3.FormBuilder.Configuration.endpoints.saveForm,
			{
				formPersistenceIdentifier: TYPO3.FormBuilder.Configuration?.formPersistenceIdentifier
				formDefinition
			},
			(data, textStatus, jqXHR) =>
				if data == 'success'
					@set('saveStatus', 'saved')
					@set('unsavedContent', false)
					if callback
						callback(true)
				else
					@set('saveStatus', 'save-error')
					if callback
						callback(false)
		)

	# ***
	# ###Private###
	# When the form definition is set anew, we select the form definition itself.
	# This mostly happens when the form itself is loaded.
	onFormDefinitionChange: (->
		return unless @get('formDefinition')
		@set('currentlySelectedRenderable', @get('formDefinition'))
	).observes('formDefinition')

	setUnsavedContentFalseWhenLoadingFormDefinition: (->
		@set('unsavedContent', false)
	).observes('formDefinition')

	contentChanged: ( ->
		@set('unsavedContent', true)
	).observes('formDefinition.__nestedPropertyChange')
}

# ***
# ##Model.Renderable##
# ... is the base class for the client-side representation of all Form Elements and Renderables.
#
# All renderables form a *tree*, and this class provides navigation and update event bubbbling.
#
# It has several unique properties:
#
# - All Renderables have a property `parentRenderable` which connect it to its parent Renderable.
# - All Renderables have an array `renderables` which contains the child renderables of the object.
# - All Renderables have a property `__nestedPropertyChange` which is changed each time a property inside
#   the object or its child-objects change. You can observe this property to get notified of changes.
#
# All properties on the object are automatically added to the event monitoring, and as soon as an element
# is added to the renderables array, the parentRenderable is set up correctly.
# ***
TYPO3.FormBuilder.Model.Renderable = Ember.Object.extend {

	# ###Public Properties###
	# * `parentRenderable`: reference to the parent `Renderable` object
	parentRenderable: null,

	# * `renderables`: Array, a reference to the child `Renderables`
	renderables: null,

	# * `__nestedPropertyChange`: You can observe this property to be notified every time a nested property changes.
	#   Do not rely on the value of this property, though!
	__nestedPropertyChange: 0,

	# * `type`: (String) form element type of this renderable -- string type identifier
	type: null

	# * `typeDefinition`: (TYPO3.FormBuilder.Model.FormElementType) form element type of this renderable -- dereferenced type definition object
	typeDefinition: ( ->
		formElementTypeName = @get('type')
		return null unless formElementTypeName

		return TYPO3.FormBuilder.Model.FormElementTypes.get(formElementTypeName)
	).property('type').cacheable()
	# ***
	# ###Private###

	# Initializer function
	init: ->
		@renderables = []
		@renderables.addArrayObserver(this)

	# called automatically when an unknown property is set, and adds the observer
	# to the new property. This effectively observes the whole object.
	setUnknownProperty: (k, v) ->
		this[k] = v
		@addObserver(k, this, 'somePropertyChanged')
		@somePropertyChanged(this, k)

	# Set the path `path` to `v` initializing empty objects as the intermediate parts
	# of the path. *You still need to trigger the `somePropertyChanged` event listener if a property
	# changed.*
	setPathRecursively: (path, v) ->
		currentObject = this
		while path.indexOf('.') > 0
			firstPartOfPath = path.slice(0, path.indexOf('.'))
			path = path.slice(firstPartOfPath.length + 1)
			if !Ember.get(currentObject, firstPartOfPath)
				Ember.set(currentObject, firstPartOfPath, {})
			currentObject = Ember.get(currentObject, firstPartOfPath)

		Ember.set(currentObject, path, v)

	# Callback which should be triggered when a nested property changes. Implements
	# the event bubbling.
	somePropertyChanged: (theInstance, propertyName) ->
		@set('__nestedPropertyChange', @get('__nestedPropertyChange') + 1);

		if (@parentRenderable)
			@parentRenderable.somePropertyChanged(@parentRenderable, "renderables.#{ @parentRenderable.get('renderables').indexOf(this) }.#{ propertyName }")

	# This callback is executed when the child `renderables` array will change.
	# We remove `parentRenderable` references on to-be-removed elements.
	arrayWillChange: (subArray, startIndex, removeCount, addCount) ->
		for i in [startIndex...startIndex+removeCount]
			subArray.objectAt(i).set('parentRenderable', null);

	# This callback is executed when the child `renderables` array has changed.
	# We add `parentRenderable` references on newly added elements, and trigger
	# a nested property change event.
	arrayDidChange: (subArray, startIndex, removeCount, addCount) ->
		for i in [startIndex...startIndex+addCount]
			subArray.objectAt(i).set('parentRenderable', this);

		@set('__nestedPropertyChange', @get('__nestedPropertyChange') + 1);
		if @parentRenderable
			@parentRenderable.somePropertyChanged(@parentRenderable, "renderables.#{ @parentRenderable.get('renderables').indexOf(this) }.renderables")

	# Helper function returning the full path of the current renderable.
	_path: (->
		if @parentRenderable
			"#{@parentRenderable.get('_path')}.renderables.#{@parentRenderable.get('renderables').indexOf(this)}"
		else
			''
	).property()

	# Find the enclosing page of the current element, by traversing
	# up the tree until the level underneath the root-level is reached (which, by
	# definition, contains PAGEs)
	findEnclosingPage: ->
		referenceRenderable = this
		while referenceRenderable.getPath('parentRenderable.parentRenderable') != null
			referenceRenderable = referenceRenderable.get('parentRenderable')
		return referenceRenderable

	# Find an enclosing composite renderable (like a section) if it exists
	# for the current element. Otherwise, returns `null`.
	#
	# *Pages are not returned by this function*
	findEnclosingCompositeRenderableWhichIsNotOnTopLevel: ->
		referenceRenderable = this
		while !referenceRenderable.getPath('typeDefinition.formBuilder._isCompositeRenderable')
			if referenceRenderable.getPath('typeDefinition.formBuilder._isTopLevel')
				return null
			referenceRenderable = referenceRenderable.get('parentRenderable')
		if referenceRenderable.getPath('typeDefinition.formBuilder._isTopLevel')
			return null
		return referenceRenderable

	# display a confirmation dialog for removing this renderable
	removeWithConfirmationDialog: ->
		thisRenderable = this
		$('<div>Are you sure that you want to remove this Element?</div>').dialog {
			dialogClass: 'typo3-formbuilder-dialog',
			title: 'Remove Element?',
			modal: true
			resizable: false
			buttons: {
				'Delete': ->
					thisRenderable.remove()
					$(this).dialog('close')
				'Cancel': ->
					$(this).dialog('close')
			}
		}
	# remove this renderable and mark the parent renderable as active
	remove: (updateCurrentRenderable = true) ->
		TYPO3.FormBuilder.Model.Form.set('currentlySelectedRenderable', @get('parentRenderable')) if updateCurrentRenderable
		@getPath('parentRenderable.renderables').removeObject(this)
}

# We override the `create` function of Ember.JS to add observers for all properties,
# and convert the child objects inside `renderables` into nested `Renderable` classes.
TYPO3.FormBuilder.Model.Renderable.reopenClass {
	create: (obj) ->
		childRenderables = obj.renderables
		delete obj.renderables

		renderable = Ember.Object.create.call(TYPO3.FormBuilder.Model.Renderable, obj)

		for k,v of obj
			renderable.addObserver(k, renderable, 'somePropertyChanged')

		if (childRenderables)
			for childRenderable in childRenderables
				renderable.get('renderables').pushObject(TYPO3.FormBuilder.Model.Renderable.create(childRenderable))

		return renderable
}

# ***
# ##Model.FormElementType##
# Container object for a form element type (i.e. a "schema object" for a form element).
# It especially contains the following structure:
TYPO3.FormBuilder.Model.FormElementType = Ember.Object.extend {
	# * formBuilder
	#    * `_isCompositeRenderable`: if TRUE, it is a composite renderable like a section or a fieldset or a page, i.e. it is allowed to insert SIMPLE FORM ELEMENTS INSIDE this element. The Form, however, has set it to FALSE
	#    * `_isTopLevel`: if TRUE, is a "Page" or a "Form", i.e. appears in the first level directly underneath the form object
	# * type
	type: null

	# list of CSS class names which should be used to represent this form element type
	__cssClassNames: ( ->
		"typo3-formbuilder-group-#{@getPath('formBuilder.group')} typo3-formbuilder-type-#{@get('type').toLowerCase().replace(/[^a-z0-9]/g, '-')}"
	).property('formBuilder.group', 'type').cacheable()
}

# ***
# ##Model.FormElementTypes##
#
# **Singleton**
#
# Contains references to all form element types currently registered,
# and a list of all type names.
#
# You can fetch a specific type by doing `get('YourTypeIdentifier')` on this object.
TYPO3.FormBuilder.Model.FormElementTypes = Ember.Object.create {

	# * `allTypeNames`: list of all form element type names which are set on this object
	allTypeNames:[]

	# initializer function
	init: ->
		return unless TYPO3.FormBuilder.Configuration?.formElementTypes?
		for typeName, typeConfiguration of TYPO3.FormBuilder.Configuration.formElementTypes
			typeConfiguration.type = typeName
			@allTypeNames.push(typeName)
			@set(typeName, TYPO3.FormBuilder.Model.FormElementType.create(typeConfiguration))
}

# ***
# ##Model.FormElementGroups##
#
# **Singleton**
#
# Contains references to all *form element groups*, which are shown as groups
# in the "create new element" panel, and also a property containing all group names.
#
# You can fetch a group by doing `get('YourGroupIdentifier')` on this object.
TYPO3.FormBuilder.Model.FormElementGroups = Ember.Object.create {
	# * `allGroupNames`: list of all form element group names
	allGroupNames: []
	init: ->
		return unless TYPO3.FormBuilder.Configuration?.formElementGroups?
		for groupName, groupConfiguration of TYPO3.FormBuilder.Configuration.formElementGroups
			@allGroupNames.push(groupName)
			@set(groupName, Ember.Object.create(groupConfiguration))
}