# #Namespace `TYPO3.FormBuilder.Utility`#
# Contains helper functions to be used directly (without object instanciations).
TYPO3.FormBuilder.Utility = {}

# ##convertToSimpleObject(Renderable)##
#
# Convert a Renderable object to a simple JavaScript object:
#
# - discarding circular references to parentRenderable
# - discarding all keys starting with __ (like the `__nestedPropertyChange` key)
# - discarding functions
# ***
convertToSimpleObject = (input) ->

	# Reference to the simple object to be filled
	simpleObject = {}

	for own key, value of input
		if (key.match(/^__/) || key == 'parentRenderable')
			# skip private properties and circular references
			continue

		if (typeof value == 'function')
			# skip function references
		else if (typeof value == 'object')
			simpleObject[key] = convertToSimpleObject value
		else
			simpleObject[key] = value

	return simpleObject

TYPO3.FormBuilder.Utility.convertToSimpleObject = convertToSimpleObject