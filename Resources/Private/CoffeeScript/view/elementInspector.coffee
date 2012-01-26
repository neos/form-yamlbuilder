# #Namespace `TYPO3.FormBuilder.View`#
#
# All views in this file render the inspector for a single form element on the right side
# of the Form Builder.
#
# Contains the following classes:
#
# * FormElementInspector
# * Editor.AbstractEditor
# * Editor.AbstractPropertyEditor
#
# Especially the last-mentioned editor class is often subclassed.
#
# ***
# ##Class View.FormElementInspector##
#
# This view renders the configured editors for the currently selected renderable.
#
# All editors are defined inside the type definition for the form element, at the key
# `formBuilder.editors`, which contains an object with all registered editors.
#
# Each form editor is configured with at least the following properties:
#
# - sorting: numerical sorting index determining the order of the editor
# - viewName: name of a view used to render this Form Element. The specified view name
#   should be a subclass of `TYPO3.FormBuilder.View.Editor.AbstractEditor`.
# - [view-specific-options]: all of the above properties are made available on
#   the view, so view-specific properties can also be specified.
TYPO3.FormBuilder.View.FormElementInspector = Ember.ContainerView.extend {
	# ***
	# ###Private###

	# the renderable which should be edited (set from outside using a binding)
	formElement: null,

	# array containing the form field editor configuration in the correct order
	orderedFormFieldEditors: ( ->
		# copy the schema to work on a clone
		formFieldEditors = $.extend({}, @getPath('formElement.typeDefinition.formBuilder.editors'))

		orderedFormFieldEditors = for k, v of formFieldEditors
			v['key'] = k
			v

		orderedFormFieldEditors.sort((a,b)-> a.sorting - b.sorting)
		return orderedFormFieldEditors
	).property('formElement.typeDefinition').cacheable()

	# When the bound form element changes, we re-compute the subviews and re-display
	# them.
	onFormElementChange: (->
		@removeAllChildren()
		return unless @formElement

		for formFieldEditor in @get('orderedFormFieldEditors')
			subViewClass = Ember.getPath(formFieldEditor.viewName)
			throw "Editor class '#{formFieldEditor.viewName}' not found" if !subViewClass

			subViewOptions = $.extend({}, formFieldEditor, {
				formElement: @formElement,
			})
			subView = subViewClass.create(subViewOptions)
			@get('childViews').pushObject(subView)
	).observes('formElement')
}

# ***
# ##Namespace TYPO3.FormBuilder.View.Editor##
#
# This namespace contains all the editors displayed inside the element inspector on
# the right side.
TYPO3.FormBuilder.View.Editor = {}

# ***
# ##Class View.Editor.AbstractEditor##
#
# Base class for custom editors. This is an extension point of the framework.
# You often will want to subclass `AbstractPropertyEditor` instead.
TYPO3.FormBuilder.View.Editor.AbstractEditor = Ember.View.extend {
	classNames: ['form-editor']

	# ###Public Properties###
	#
	# - `formElement`: reference to the currently selected form element
	formElement: null
}

# ***
# ##Class View.Editor.AbstractPropertyEditor##
#
# Most-often used base class for custom editors. This is an extension point of the framework.
#
# This property editor should be used if only *a single property* will be edited
# using the editor. Then, you can work with a higher level of abstraction, not manipulating
# the `formElement` directly:
#
# - `propertyPath` (string): The path to the to-be-edited value, relative from the current form element.
# - `value`: The value residing underneath `propertyPath`; as this is a computed property make sure to always
#   use @get and @set.
# - `valueChanged()`: You should call this API method every time you changed `value` or a sub property of `value`.
#   This triggers the event listeners in the rest of the UI.
TYPO3.FormBuilder.View.Editor.AbstractPropertyEditor = TYPO3.FormBuilder.View.Editor.AbstractEditor.extend {
	# ###Public Properties###
	#
	# - `propertyPath`: the property path at which the current value resides, relative to the current @formElement.
	#   Required.
	propertyPath: null,

	# - `defaultValue`: if value at `propertyPath` is not set, it will be initialized with this default value.
	# this can be overridden in subclasses, f.e. the `validatorEditor` sets this to a computed property always
	# returning a fresh array instance.
	defaultValue: '',

	# - `valueChanged()`: callback function which needs to be executed when the value changes
	valueChanged: ->
		@get('formElement').somePropertyChanged?(@formElement, @get('propertyPath'))

	# - `value`: Accessor for the current value underneath `propertyPath`
	# ***
	# ###Private###
	value: ( (k, v) ->
		if v != undefined
			@formElement.setPath(@get('propertyPath'), v)
			# Ember.JS Hint: It is EXTREMELY IMPORTANT that the computed property SETTER returns the given value as well!
			return v
		else
			value = @formElement.getPath(@get('propertyPath'))
			if value == undefined
				@formElement.setPathRecursively(@get('propertyPath'), @get('defaultValue'))
				value = @formElement.getPath(@get('propertyPath'))
			return value
	).property('propertyPath', 'formElement').cacheable()


}