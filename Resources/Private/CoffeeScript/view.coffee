TYPO3.FormBuilder.View = {}

TYPO3.FormBuilder.View.AvailableFormElementsView = Ember.CollectionView.extend {
	contentBinding: 'TYPO3.FormBuilder.Model.AvailableFormElements.content'
	click: -> console.log('click')

	itemViewClass: Ember.View.extend {
		templateName: 'item'
		didInsertElement: ->
			this.$().draggable {
				connectToSortable: '.typo3-form-sortable'
				helper: ->
					$('<div>' + $(this).html() + '</div>')
				revert: 'invalid'
			}
	}
}

TYPO3.FormBuilder.View.FormPageView = Ember.View.extend {
	formPagesBinding: 'TYPO3.FormBuilder.Model.FormDefinition.pages',
	currentPageIndex: 0

	page: Ember.computed(->
		@get('formPages')?.get(@get('currentPageIndex'))
	).property('formPages', 'currentPageIndex').cacheable()

	renderPageIfPageObjectChanges: (->

		formDefinition = TYPO3.FormBuilder.Utility.convertToSimpleObject(TYPO3.FormBuilder.Model.FormDefinition)
		$.post(
			TYPO3.FormBuilder.Configuration.endpoints.formPageRenderer,
			{ formDefinition },
			(data) =>
				this.$().html(data);
				@postProcessRenderedPage();
		)
	).observes('page'),

	postProcessRenderedPage: ->
		this.$().find('fieldset').addClass('typo3-form-sortable').sortable {
			revert: 'true'
		};
}