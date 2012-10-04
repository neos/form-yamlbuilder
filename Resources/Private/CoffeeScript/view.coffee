# <!--
# This script belongs to the TYPO3 Flow package "TYPO3.FormBuilder".
#
# It is free software; you can redistribute it and/or modify it under
# the terms of the GNU Lesser General Public License, either version 3
#  of the License, or (at your option) any later version.
#
# The TYPO3 project - inspiring people to share!
# -->


# #Namespace `TYPO3.FormBuilder.View`#
#
# This namespace contains view classes, mostly subclassing `Ember.View`, containing
# output-related logic.
#
# This file contains some generic classes which are useful at many points in the
# application:
#
# * ContainerView
# * Select
# * TextField
#
# several other classes inside this namespace are added inside the "view" folder.

TYPO3.FormBuilder.View = {}


# ***
# ##View.ContainerView##
#
# An extension of `Ember.ContainerView` which gets the fully instanciated child-views
# passed from the outside in the `instanciatedViews` property, and renders them.
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

# ***
# ##View.TextField
#
# A special text field which contains some validation logic, i.e. which
# accepts only values of a special type.
#
# When using this text field, you should not bind the `value` property
# like when using a normal text field, but instead the `validatedValue` property
# which is only updated when the text field contents are valid according
# to the validator specified with `validatorName`.
#
# ###Usage
#
# Example: `{{view TYPO3.FormBuilder.View.TextField validatedValueBinding="maximum" validatorName="TYPO3.FormBuilder.Validators.isNumberOrBlank" }}`
#
# ###Public Properties
TYPO3.FormBuilder.View.TextField = Ember.TextField.extend {
	# * `validatorName`: Path to a validate-function which should return `true`
	#   in case the validation is successful, `false` otherwise.
	validatorName: null

	_lastValidValue: false

	validate: (v) ->
		if @get('validatorName')
			validator = Ember.getPath(@get('validatorName'))
			return validator.call(this, v)
		return true

	# * `validatedValue`: Make sure to bind to `validatedValue` instead of `value`.
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
