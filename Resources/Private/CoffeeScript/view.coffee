TYPO3.FormBuilder.View = {}

#
# Render the current page of the form server-side
#
TYPO3.FormBuilder.View.FormPageView = Ember.View.extend {
	formPagesBinding: 'TYPO3.FormBuilder.Model.Form.formDefinition.renderables',

	currentPageIndex: (->
		currentlySelectedRenderable = TYPO3.FormBuilder.Model.Form.get('currentlySelectedRenderable')
		return 0 unless currentlySelectedRenderable

		enclosingPage = currentlySelectedRenderable.findEnclosingPage()
		return 0 unless enclosingPage

		return enclosingPage.getPath('parentRenderable.renderables').indexOf(enclosingPage)
	).property('TYPO3.FormBuilder.Model.Form.currentlySelectedRenderable').cacheable()

	currentAjaxRequest: null,

	page: Ember.computed(->
		@get('formPages')?.get(@get('currentPageIndex'))
	).property('formPages', 'currentPageIndex').cacheable()


	renderPageIfPageObjectChanges: (->
		if (!TYPO3.FormBuilder.Model.Form.get('formDefinition')?.get('identifier'))
			return
		if @currentAjaxRequest
			@currentAjaxRequest.abort()

		if @timeout
			window.clearTimeout(@timeout)
		@timeout = window.setTimeout( =>
			formDefinition = TYPO3.FormBuilder.Utility.convertToSimpleObject(TYPO3.FormBuilder.Model.Form.get('formDefinition'))
			@currentAjaxRequest = $.post(
				TYPO3.FormBuilder.Configuration.endpoints.formPageRenderer,
				{ formDefinition, currentPageIndex: @get('currentPageIndex') },
				(data, textStatus, jqXHR) =>
					return unless @currentAjaxRequest == jqXHR
					this.$().html(data);
					@postProcessRenderedPage();
			)
		, 300)

	).observes('page', 'page.__nestedPropertyChange'),

	postProcessRenderedPage: ->
		this.$().find('[data-element]').parent().addClass('typo3-form-sortable').sortable {
			revert: 'true'
			update: (e, o) =>
				pathOfMovedElement = $(o.item.context).attr('data-element')
				movedRenderable = @findRenderableForPath(pathOfMovedElement)
				movedRenderable.getPath('parentRenderable.renderables').removeObject(movedRenderable);


				nextElementPath = $(o.item.context).nextAll('[data-element]').first().attr('data-element')
				nextElement = @findRenderableForPath(nextElementPath) if nextElementPath
				previousElementPath = $(o.item.context).prevAll('[data-element]').first().attr('data-element')
				previousElement = @findRenderableForPath(previousElementPath) if previousElementPath
				throw 'Next Element or Previous Element need to be set. Should not happen...' if !nextElement && !previousElement

				if nextElement
					referenceElementIndex = nextElement.getPath('parentRenderable.renderables').indexOf(nextElement)
					nextElement.getPath('parentRenderable.renderables').insertAt(referenceElementIndex, movedRenderable)
				else if previousElement
					referenceElementIndex = previousElement.getPath('parentRenderable.renderables').indexOf(previousElement)
					previousElement.getPath('parentRenderable.renderables').insertAt(referenceElementIndex+1, movedRenderable)
		};
		@onCurrentElementChanges()

	onCurrentElementChanges: (->
		renderable = TYPO3.FormBuilder.Model.Form.get('currentlySelectedRenderable')
		return unless renderable

		@$().find('.formbuilder-form-element-selected').removeClass('formbuilder-form-element-selected');
		identifierPath = renderable.identifier
		while renderable = renderable.parentRenderable
			identifierPath = renderable.identifier + '/' + identifierPath

		@$().find('[data-element="' + identifierPath + '"]').addClass('formbuilder-form-element-selected')

	).observes('TYPO3.FormBuilder.Model.Form.currentlySelectedRenderable')

	findRenderableForPath: (path) ->
		expandedPathToClickedElement = path.split('/')
		expandedPathToClickedElement.shift() # first element is form identifier
		expandedPathToClickedElement.shift() # second one is page identifier

		currentRenderable = @get('page')
		for pathPart in expandedPathToClickedElement
			for renderable in currentRenderable.get('renderables')
				if renderable.identifier == pathPart
					currentRenderable = renderable
					break
		return currentRenderable


	click: (e) ->
		pathToClickedElement = ($(e.target).closest('[data-element]').attr('data-element'));

		return unless pathToClickedElement
		TYPO3.FormBuilder.Model.Form.set('currentlySelectedRenderable', @findRenderableForPath(pathToClickedElement));
}

TYPO3.FormBuilder.View.ContainerView = Ember.ContainerView.extend {
	instanciatedViews: null
	onInstanciatedViewsChange: (->
		@removeAllChildren()
		for view in @get('instanciatedViews')
			@get('childViews').pushObject(view)
	).observes('instanciatedViews')
}

TYPO3.FormBuilder.View.Select = Ember.Select.extend {
	attributeBindings: ['disabled']
}