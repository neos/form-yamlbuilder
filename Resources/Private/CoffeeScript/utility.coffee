# <!--
# This file is part of the Neos.Form.YamlBuilder package.
#
# (c) Contributors of the Neos Project - www.neos.io
#
# This package is Open Source Software. For the full copyright and license
# information, please view the LICENSE file which was distributed with this
# source code.
# -->


# #Namespace `Neos.Form.YamlBuilder.Utility`#
# Contains helper functions to be used directly (without object instanciations).
Neos.Form.YamlBuilder.Utility = {}

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

Neos.Form.YamlBuilder.Utility.convertToSimpleObject = convertToSimpleObject

# ##getUri(baseUri, [presetName])
#
# Get an URI which is comprised of base URI, form persistence identifier and passed preset.
Neos.Form.YamlBuilder.Utility.getUri = (baseUri, presetName = Neos.Form.YamlBuilder.Configuration.presetName) ->
	 uri = baseUri + "?formPersistenceIdentifier=#{encodeURIComponent(Neos.Form.YamlBuilder.Configuration.formPersistenceIdentifier)}&presetName=#{encodeURIComponent(presetName)}"
	 return uri
