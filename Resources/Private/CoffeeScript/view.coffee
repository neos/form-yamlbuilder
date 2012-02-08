# #Namespace `TYPO3.FormBuilder.View`#
#
# This namespace contains view classes, mostly subclassing `Ember.View`, containing
# output-related logic.
#
# This file contains the following classes:
#
# * FormPageView
# * ContainerView
# * Select
#
# several other classes inside this namespace are added inside the "view" folder.

TYPO3.FormBuilder.View = {}

# ***
# ##View.FormPageView##
#
# This view renders the form in the middle of the screen; triggering AJAX requests
# to the server as needed when the form definition changes.
# ***
# ###Private###
TYPO3.FormBuilder.View.FormPageView = Ember.View.extend {
	formPagesBinding: 'TYPO3.FormBuilder.Model.Form.formDefinition.renderables',
	presetName: null,

	# find the current page index based on the currently selected renderable; by traversing
	# up the renderable hierarchy.
	currentPageIndex: (->
		currentlySelectedRenderable = TYPO3.FormBuilder.Model.Form.get('currentlySelectedRenderable')
		return 0 unless currentlySelectedRenderable

		enclosingPage = currentlySelectedRenderable.findEnclosingPage()
		return 0 unless enclosingPage

		return 0 unless enclosingPage.getPath('parentRenderable.renderables')

		return enclosingPage.getPath('parentRenderable.renderables').indexOf(enclosingPage)
	).property('TYPO3.FormBuilder.Model.Form.currentlySelectedRenderable').cacheable()

	# Reference to the current Page (instance of `TYPO3.Form.Model.Renderable`) which is shown in the middle.
	page: Ember.computed(->
		@get('formPages')?.get(@get('currentPageIndex'))
	).property('formPages', 'currentPageIndex').cacheable()

	# Reference to the currently running AJAX request, if any.
	currentAjaxRequest: null,

	isLoadingBinding: 'TYPO3.FormBuilder.Model.Form.currentlyLoadingPreview'

	# Function which renders the page if something changes on the form, with a little delay of 300 ms.
	# After the response has been received from the server, it triggers the `postProcessPage` function.
	renderPageIfPageObjectChanges: (->
		return unless TYPO3.FormBuilder.Model.Form.getPath('formDefinition.identifier')

		if @currentAjaxRequest
			@currentAjaxRequest.abort()

		if @timeout
			window.clearTimeout(@timeout)

		@timeout = window.setTimeout( =>
			formDefinition = TYPO3.FormBuilder.Utility.convertToSimpleObject(TYPO3.FormBuilder.Model.Form.get('formDefinition'))
			@set('isLoading', true)
			@currentAjaxRequest = $.post(
				TYPO3.FormBuilder.Configuration.endpoints.formPageRenderer,
				{
					formDefinition,
					currentPageIndex: @get('currentPageIndex'),
					presetName: @get('presetName')
				},
				(data, textStatus, jqXHR) =>
					return unless @currentAjaxRequest == jqXHR
					this.$().html(data);
					@set('isLoading', false)
					@postProcessRenderedPage();
			)
		, 300)
	).observes('page', 'page.__nestedPropertyChange'),

	# Post process the rendered page:
	#
	# - update the element selection
	# - making the elements sortable and handling drag/drop.
	postProcessRenderedPage: ->
		@onCurrentElementChanges()
		this.$().find('[data-element]').parent().addClass('typo3-form-sortable').sortable {
			revert: 'true'
			update: (e, o) =>

				# remove the to-be-moved object from its parent renderable
				pathOfMovedElement = $(o.item.context).attr('data-element')
				movedRenderable = @findRenderableForPath(pathOfMovedElement)
				movedRenderable.getPath('parentRenderable.renderables').removeObject(movedRenderable);

				# find reference element either before or after the currently inserted element
				nextElementPath = $(o.item.context).nextAll('[data-element]').first().attr('data-element')
				nextElement = @findRenderableForPath(nextElementPath) if nextElementPath
				previousElementPath = $(o.item.context).prevAll('[data-element]').first().attr('data-element')
				previousElement = @findRenderableForPath(previousElementPath) if previousElementPath

				# insert before next / after previous element
				if nextElement
					referenceElementIndex = nextElement.getPath('parentRenderable.renderables').indexOf(nextElement)
					nextElement.getPath('parentRenderable.renderables').insertAt(referenceElementIndex, movedRenderable)
				else if previousElement
					referenceElementIndex = previousElement.getPath('parentRenderable.renderables').indexOf(previousElement)
					previousElement.getPath('parentRenderable.renderables').insertAt(referenceElementIndex+1, movedRenderable)
				else
					throw 'Next Element or Previous Element need to be set. Should not happen...'
		};

	# this callback highlights the currently selected element, if any.
	onCurrentElementChanges: (->
		renderable = TYPO3.FormBuilder.Model.Form.get('currentlySelectedRenderable')
		return unless renderable

		@$().find('.typo3-formbuilder-form-element-selected').removeClass('typo3-formbuilder-form-element-selected');
		identifierPath = renderable.identifier
		while renderable = renderable.parentRenderable
			identifierPath = renderable.identifier + '/' + identifierPath

		@$().find('[data-element="' + identifierPath + '"]').addClass('typo3-formbuilder-form-element-selected')
	).observes('TYPO3.FormBuilder.Model.Form.currentlySelectedRenderable')

	# click handler, triggered if an element is clicked. We try to determine the path to the clicked element,
	# and select it accordingly.
	click: (e) ->
		pathToClickedElement = ($(e.target).closest('[data-element]').attr('data-element'));

		return unless pathToClickedElement
		TYPO3.FormBuilder.Model.Form.set('currentlySelectedRenderable', @findRenderableForPath(pathToClickedElement));

	# helper function, which, given an element path, returns the appropriate renderable.
	findRenderableForPath: (path) ->
		expandedPathToClickedElement = path.split('/')
		expandedPathToClickedElement.shift() # first element is form identifier, thus we can remove it
		expandedPathToClickedElement.shift() # second one is page identifier, thus we can remove it as we are on only one page

		currentRenderable = @get('page')
		for pathPart in expandedPathToClickedElement
			for renderable in currentRenderable.get('renderables')
				if renderable.identifier == pathPart
					currentRenderable = renderable
					break
		return currentRenderable
}

# ***
# ##View.ContainerView##
#
# An extension of `Ember.ContainerView` which gets the fully instanciated child-views
# passed from the outside in the "instanciatedViews" property, and renders them.
#
# This is a low-level class which you typically do not need to use directly.
#
# ***
# ###Public Properties###
TYPO3.FormBuilder.View.ContainerView = Ember.ContainerView.extend {
	# * `instanciatedViews`: an ember array of instanciated view objects; and every
	#   time this array changes the childViews are removed and re-added, triggering re-draw.
	instanciatedViews: null
	onInstanciatedViewsChange: (->
		@removeAllChildren()
		for view in @get('instanciatedViews')
			@get('childViews').pushObject(view)
	).observes('instanciatedViews')
}

# ***
# ##View.Select##
#
# extended version of `Ember.Select` which makes the `disabled` property of the
# select exposed via attribute bindings.
#
TYPO3.FormBuilder.View.Select = Ember.Select.extend {
	attributeBindings: ['disabled']
}