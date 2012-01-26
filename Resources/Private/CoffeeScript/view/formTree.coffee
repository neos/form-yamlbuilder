

#
# Structure of the form
#
TYPO3.FormBuilder.View.FormTree = Ember.View.extend {
	formDefinitionBinding: 'TYPO3.FormBuilder.Model.Form.formDefinition'
	templateName: 'FormTree'

	_tree: null
	didInsertElement: ->
		@_tree = @$().find('.tree')
		@_tree.dynatree {
			onActivate: (node)->
				TYPO3.FormBuilder.Model.Form.set('currentlySelectedRenderable', node.data.formRenderable)
			dnd: {
				onDragStart: -> true
				autoExpandMS: 300
				onDragEnter: (targetNode, sourceNode) ->
					targetNodeIsCompositeRenderable = targetNode.data.formRenderable.getPath('typeDefinition.formBuilder._isCompositeRenderable')

					if sourceNode.getLevel() == 1
						# source node is a PAGE
						if (targetNode.getLevel() == 1)
							return ['before', 'after']
						else
							return false
					else
						# source node is NO page
						if targetNode.getLevel() == 1
							# ... but target node is -> we only allow INSERTING
							return ['over']
						else
							# both source and target nodes are no page
							if targetNodeIsCompositeRenderable
								return ['before', 'over', 'after']
							else
								return ['before', 'after']

				onDrop: (targetNode, sourceNode, hitMode)->
					sourceRenderable = sourceNode.data.formRenderable
					targetRenderable = targetNode.data.formRenderable

					# disconnect source renderable from parent object
					sourceRenderable.getPath('parentRenderable.renderables').removeObject(sourceRenderable)

					# add renderable to target object
					if hitMode == 'over'
						# ... add object as last child
						targetRenderable.get('renderables').pushObject(sourceRenderable)
					else
						indexOfTargetRenderable = targetRenderable.getPath('parentRenderable.renderables').indexOf(targetRenderable)
						if hitMode == 'before'
							targetRenderable.getPath('parentRenderable.renderables').insertAt(indexOfTargetRenderable, sourceRenderable)
						else
							targetRenderable.getPath('parentRenderable.renderables').insertAt(indexOfTargetRenderable+1, sourceRenderable)

			}
		}
		@updateTreeStateFromModel(@_tree.dynatree('getRoot'), @getPath('formDefinition.renderables'))

	updateTree: (->
		return unless @_tree?.dynatree('getTree').visit

		expandedNodePaths = []
		@_tree.dynatree('getTree').visit (node) -> expandedNodePaths.push(node.data.key) if node.isExpanded()

		activeNodePath = @_tree.dynatree('getActiveNode')?.data.key

		@_tree.dynatree('getRoot').removeChildren?()
		@updateTreeStateFromModel(@_tree.dynatree('getRoot'), @getPath('formDefinition.renderables'))

		for expandedNodePath in expandedNodePaths
			@_tree.dynatree('getTree').getNodeByKey(expandedNodePath)?.expand(true)
		@_tree.dynatree('getTree').getNodeByKey(activeNodePath)?.activate(true)
	).observes('formDefinition.__nestedPropertyChange')

	updateTreeStateFromModel: (dynaTreeParentNode, currentListOfSubRenderables) ->
		return if !currentListOfSubRenderables

		for subRenderable in currentListOfSubRenderables
			newNode = dynaTreeParentNode.addChild {
				key: subRenderable.get('_path')
				title: if subRenderable.label then subRenderable.label else subRenderable.identifier
				formRenderable: subRenderable
			}
			@updateTreeStateFromModel(newNode, subRenderable.getPath('renderables'))

	updateCurrentlySelectedNode: ( ->
		activeNodePath = TYPO3.FormBuilder.Model.Form.getPath('currentlySelectedRenderable._path')
		@_tree.dynatree('getTree').getNodeByKey?(activeNodePath)?.activate(true)
	).observes('TYPO3.FormBuilder.Model.Form.currentlySelectedRenderable')

	showFormOptions: ->
		#debugger
		#console.log(TYPO3.FormBuilder.Model.Form.get('currentlySelectedRenderable'))
		#Ember.run ->
		TYPO3.FormBuilder.Model.Form.set('currentlySelectedRenderable', TYPO3.FormBuilder.Model.Form.get('formDefinition'));
		#console.log(TYPO3.FormBuilder.Model.Form.get('currentlySelectedRenderable'))

}