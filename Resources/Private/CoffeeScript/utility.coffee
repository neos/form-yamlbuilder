TYPO3.FormBuilder.Utility = {}

convertToSimpleObject = (input) ->
	simpleObject = {}

	for own key, value of input
		if (key.match(/^__/) || key == 'parentRenderable')
			continue

		if (!value)
			#skip
		else if (typeof value == 'function')
			# skip
		else if (typeof value == 'object')
			simpleObject[key] = convertToSimpleObject value
		else
			simpleObject[key] = value

	return simpleObject

TYPO3.FormBuilder.Utility.convertToSimpleObject = convertToSimpleObject