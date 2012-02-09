# #Namespace `TYPO3.FormBuilder.View`#
#
# This namespace contains view classes, mostly subclassing `Ember.View`, containing
# output-related logic.
#
# This file contains the following classes:
#
# * ContainerView
# * Select
#
# several other classes inside this namespace are added inside the "view" folder.

TYPO3.FormBuilder.View = {}


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




TYPO3.FormBuilder.View.TextField = Ember.TextField.extend {
	_lastValidValue: false
	validatorName: null

	validate: (v) ->
		if @get('validatorName')
			validator = Ember.getPath(@get('validatorName'))
			return validator.call(this, v)
		return true

	validatedValue: ((k, v) ->
		if arguments.length >= 2
			if @validate(v)
				this._lastValidValue = v

			return this._lastValidValue
		else
			return this._lastValidValue
	).property().cacheable()


	valueBinding: 'validatedValue'
}
