# <!--
# This script belongs to the FLOW3 package "TYPO3.FormBuilder".
#
# It is free software; you can redistribute it and/or modify it under
# the terms of the GNU Lesser General Public License, either version 3
#  of the License, or (at your option) any later version.
#
# The TYPO3 project - inspiring people to share!
# -->


# ***
# ##View.Stage##
#
# This view renders the form in the middle of the screen; triggering AJAX requests
# to the server as needed when the form definition changes.
# ***
# ###Private###
TYPO3.FormBuilder.View.Stage = Ember.View.extend {
	formPagesBinding: 'TYPO3.FormBuilder.Model.Form.formDefinition.renderables',

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
					presetName: TYPO3.FormBuilder.Configuration.presetName
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
	# - disable all form elements such that they are not clickable
	# - update the element selection
	# - making the elements sortable and handling drag/drop.
	postProcessRenderedPage: ->
		@onCurrentElementChanges()

		# - disable all form elements such that they are not clickable
		this.$().find('[data-element]').on('click dblclick select focus keydown keypress keyup mousedown mouseup', (e)->
			e.preventDefault()
		)
		this.$().find('form').submit (e) ->
			e.preventDefault()

		this.$().find('[data-element]').parent().addClass('typo3-form-sortable').sortable {
			revert: 'true'
			start: (e, o) =>
				# starting drag/drop will disable the current AJAX request and clear the timeout
				# in order to prevent refreshes when the page loads
				if @currentAjaxRequest
					@currentAjaxRequest.abort()

				if @timeout
					window.clearTimeout(@timeout)

				@set('isLoading', false)

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