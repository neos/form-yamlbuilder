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
	# ###Public API###
	# * `formDefinition`: Reference to the `Renderable` object for the form.
	formDefinition: null,
	# * `currentlySelectedRenderable`: Reference to the currently selected `Renderable` object.
	currentlySelectedRenderable: null

	onFormDefinitionChange: (->
		return unless @get('formDefinition')
		@set('currentlySelectedRenderable', @get('formDefinition'))
	).observes('formDefinition')
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

	# ###Public API###
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
	# changed.
	setPathRecursively: (path, v) ->
		currentObject = this
		while path.indexOf('.') > 0
			firstPartOfPath = path.slice(0, path.indexOf('.'))
			path = path.slice(firstPartOfPath.length + 1)
			if !currentObject[firstPartOfPath]
				currentObject[firstPartOfPath] = {}
			currentObject = currentObject[firstPartOfPath]

		currentObject[path] = v

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

	# the *page* is everything which is added as direct child to the form, i.e. which does not have a grandparent
	findEnclosingPage: ->
		referenceRenderable = this
		while referenceRenderable.getPath('parentRenderable.parentRenderable') != null
			referenceRenderable = referenceRenderable.get('parentRenderable')
		return referenceRenderable
}

# We override the `create` function of Ember.JS to add observers for all properties,
# and convert the child objects inside `renderables` into nested Renderable classes.
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
TYPO3.FormBuilder.Model.FormElementType = Ember.Object.extend {
	# formBuilder
		# _isCompositeRenderable: false
		# _isPage: false
}

# ***
# ##Model.FormElementTypes##
#
# **Singleton**
#
# Contains references to all form element types currently registered,
# and a list of all type names.
# ***
TYPO3.FormBuilder.Model.FormElementTypes = Ember.Object.create {

	# list of all form element type names which are set on this object
	allTypeNames:[]

	# initializer function
	init: ->
		return unless TYPO3.FormBuilder.Configuration?.formElementTypes?
		for typeName, typeConfiguration of TYPO3.FormBuilder.Configuration.formElementTypes
			@allTypeNames.push(typeName)
			@set(typeName, TYPO3.FormBuilder.Model.FormElementType.create(typeConfiguration))
}

# ***
# ##Model.FormElementGroups##
#
# **Singleton**
#
# Contains references to all *form element groups*, which are shown as groups
# in the "create new element" panel.
TYPO3.FormBuilder.Model.FormElementGroups = Ember.Object.create {
	allGroupNames: []
	init: ->
		return unless TYPO3.FormBuilder.Configuration?.formElementGroups?
		for groupName, groupConfiguration of TYPO3.FormBuilder.Configuration.formElementGroups
			@allGroupNames.push(groupName)
			@set(groupName, Ember.Object.create(groupConfiguration))

}