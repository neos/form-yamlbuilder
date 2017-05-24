# <!--
# This file is part of the Neos.Formbuilder package.
#
# (c) Contributors of the Neos Project - www.neos.io
#
# This package is Open Source Software. For the full copyright and license
# information, please view the LICENSE file which was distributed with this
# source code.
# -->


# #Namespace `Neos.FormBuilder.View`#
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

Neos.FormBuilder.View = {}


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
Neos.FormBuilder.View.ContainerView = Ember.ContainerView.extend {
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
Neos.FormBuilder.View.Select = Ember.Select.extend {
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
# Example: `{{view Neos.FormBuilder.View.TextField validatedValueBinding="maximum" validatorName="Neos.FormBuilder.Validators.isNumberOrBlank" }}`
#
# ###Public Properties
Neos.FormBuilder.View.TextField = Ember.TextField.extend {
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
