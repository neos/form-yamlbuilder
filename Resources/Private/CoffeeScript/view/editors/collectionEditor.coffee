TYPO3.FormBuilder.View.Editor.AbstractCollectionEditor = TYPO3.FormBuilder.View.Editor.AbstractPropertyEditor.extend {
	# ###Public Properties###
	# * `availableCollectionElements`: JSON object of available sub elements, where each element has the following options:
	#
	#    * `label`: human-readable label of the validator
	#    * `sorting`: sorting index to be used for the validator
	#    * `name`: Validator class name, if not specified the `TYPO3.FormBuilder.View.Editor.ValidatorEditor.DefaultValidatorEditor` is used.
	#    * `options`: Validator options to be set (JSON object)
	#    * `required`: (boolean) if TRUE; it is required validator which is not de-selectable
	availableCollectionElements: null,


	# ***
	# ###Private###
	defaultValue: (-> []).property().cacheable()

	# we only show the validators view if there are validators available or already shown
	isVisible: (->
		collectionElementsAvailable = !@get('noCollectionElementsAvailable')
		collectionEditorViewsFound = @get('collectionEditorViews').length > 0
		return collectionElementsAvailable or collectionEditorViewsFound
	).property('collectionEditorViews', 'noCollectionElementsAvailable').cacheable()

	# list of initialized views, one for each collection editor
	collectionEditorViews: null

	prompt: Ember.required()

	# initializer.
	init: ->
		@_super()
		@set('collectionEditorViews', [])

		@updateCollectionEditorViews()

	# sort the available collection elements based on their sorting property
	sortedAvailableCollectionElements: (->
		sortedCollectionElements = []
		for key, collectionElementTemplate of @get('availableCollectionElements')
			continue if @isCollectionElementTemplateFoundInCollection(collectionElementTemplate)
			sortedCollectionElements.push($.extend({key}, collectionElementTemplate))

		sortedCollectionElements.sort((a, b) -> a.sorting - b.sorting)
		return sortedCollectionElements
	).property('availableCollectionElements', 'formElement.__nestedPropertyChange').cacheable()

	# if TRUE, no collection elements are available.
	noCollectionElementsAvailable: ( ->
		@get('sortedAvailableCollectionElements').length == 0
	).property('sortedAvailableCollectionElements').cacheable()

	# this property needs to be bound to the current selection, of the "collection element"
	# select field, such that we can observe this value for changes.
	addCollectionElementSelection: null

	# helper function which adds a new collection element
	addCollectionElement: (->
		collectionElementToBeAdded = @get('addCollectionElementSelection')
		return unless collectionElementToBeAdded

		@get('value').push {
			name: collectionElementToBeAdded.name
			options: collectionElementToBeAdded.options || {}
		}

		@valueChanged()
		@updateCollectionEditorViews()

		# reset the "addCollectionElement" dropdown
		@set('addCollectionElementSelection', null)
	).observes('addCollectionElementSelection')

	# helper function which updates the validator editor views.
	updateCollectionEditorViews: (->
		@addRequiredCollectionElementsIfNeeded()

		collection = @get('value')

		availableCollectionElements = @get('availableCollectionElements')
		return unless availableCollectionElements

		collectionEditorViews = []

		for collectionElement, i in collection
			for key, availableCollectionElementTemplate of availableCollectionElements
				if availableCollectionElementTemplate.name == collectionElement.name # TODO: also check options of validator!
					# we found the correct validatorTemplate for the current validator,
					# thus we can output label and determine the view to be used.
					collectionElementEditor = Ember.getPath(availableCollectionElementTemplate.viewName || 'TYPO3.FormBuilder.View.Editor.ValidatorEditor.DefaultValidatorEditor')
					throw "Validator Editor class '#{availableCollectionElementTemplate.viewName}' not found" if !collectionElementEditor
					collectionElementEditorOptions = $.extend({
						elementIndex: i
						valueChanged: =>
							@valueChanged()
						updateCollectionEditorViews: =>
							@updateCollectionEditorViews()
						collection: @get('value')
					}, availableCollectionElementTemplate)
					collectionEditorViews.push(collectionElementEditor.create(collectionElementEditorOptions))
					break

		@set('collectionEditorViews', collectionEditorViews)
	).observes('value', 'availableCollectionElements')

	# add the required validators if needed to the list of validators
	addRequiredCollectionElementsIfNeeded: ->
		collection = @get('value')
		availableCollectionElements = @get('availableCollectionElements')

		requiredAndMissingCollectionElements = []

		for key, availableCollectionElementTemplate of availableCollectionElements
			continue unless availableCollectionElementTemplate.required # continue if validator template is not required

			if !@isCollectionElementTemplateFoundInCollection(availableCollectionElementTemplate)
				requiredAndMissingCollectionElements.push(key)

		for collectionElementName in requiredAndMissingCollectionElements
			collection.push({
				name: availableCollectionElements[collectionElementName].name
				options: $.extend({}, availableCollectionElements[collectionElementName].options)
			})


	# is a validator template found in the list of validators?
	isCollectionElementTemplateFoundInCollection: (collectionElementTemplate) ->
		collection = @get('value')
		for collectionElement in collection
			if collectionElementTemplate.name == collectionElement.name # TODO: also check options of validator!
				return true

		return false

}