TYPO3.FormBuilder.View.FormElementInspector = Ember.ContainerView.extend {

	# the renderable which should be edited
	formElement: null,

	orderedFormFieldEditors: ( ->
		# copy the schema to work on a clone
		formFieldEditors = $.extend({}, @getPath('formElement.typeDefinition.formBuilder.formFieldEditors'))

		orderedFormFieldEditors = for k, v of formFieldEditors
			v['key'] = k
			v

		orderedFormFieldEditors.sort((a,b)-> a.sorting - b.sorting)
		return orderedFormFieldEditors
	).property('formElement.typeDefinition').cacheable()


	onFormElementChange: (->
		@removeAllChildren()
		return unless @formElement
		#formElement = @formElement

		for formFieldEditor in @get('orderedFormFieldEditors')
			subViewClass = Ember.getPath(formFieldEditor.viewName)
			throw "Editor class '#{formFieldEditor.viewName}' not found" if !subViewClass

			subViewOptions = $.extend({}, formFieldEditor, {
				formElement: @formElement,
			})
			subView = subViewClass.create(subViewOptions)
			@get('childViews').push(subView)
		@rerender()
	).observes('formElement')
}



TYPO3.FormBuilder.View.Editor = {}
TYPO3.FormBuilder.View.Editor.AbstractEditor = Ember.View.extend {
	classNames: ['form-editor']
	formElement: null
}

TYPO3.FormBuilder.View.Editor.AbstractPropertyEditor = TYPO3.FormBuilder.View.Editor.AbstractEditor.extend {
	### PUBLIC API ###
	# the property path at which the current value resides, relative to the current @formElement.
	# Required.
	propertyPath: null,

	### API FOR SUBCLASSES ###

	# if value is not set, it will be initialized with this default value.
	# this can be overridden in subclasses.
	defaultValue: '',

	# accessor for the current value
	value: ( (k, v) ->
		if v != undefined
			@formElement.setPath(@get('propertyPath'), v)
			# EXTREMELY IMPORTANT that the computed property SETTER returns the given value as well!
			return v
		else
			value = @formElement.getPath(@get('propertyPath'))
			if value == undefined
				@formElement.setPathRecursively(@get('propertyPath'), @get('defaultValue'))
				value = @formElement.getPath(@get('propertyPath'))
			return value
	).property('propertyPath', 'formElement').cacheable()

	# callback function which needs to be executed when the value changes
	valueChanged: ->
		@get('formElement').somePropertyChanged?(@formElement, @get('propertyPath'))

}