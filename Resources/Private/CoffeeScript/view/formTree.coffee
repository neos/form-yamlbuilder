

#
# Structure of the form
#
TYPO3.FormBuilder.View.FormTree = Ember.View.extend {
	formDefinitionBinding: 'TYPO3.FormBuilder.Model.Form.formDefinition'
	didInsertElement: ->
		@$().dynatree {
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
		@updateTreeStateFromModel(@$().dynatree('getRoot'), @getPath('formDefinition.renderables'))

	updateTree: (->
		return unless @$().dynatree('getTree').visit

		expandedNodePaths = []
		@$().dynatree('getTree').visit (node) -> expandedNodePaths.push(node.data.key) if node.isExpanded()

		activeNodePath = @$().dynatree('getActiveNode')?.data.key

		@$().dynatree('getRoot').removeChildren?()
		@updateTreeStateFromModel(@$().dynatree('getRoot'), @getPath('formDefinition.renderables'))

		for expandedNodePath in expandedNodePaths
			@$().dynatree('getTree').getNodeByKey(expandedNodePath).expand(true)
		@$().dynatree('getTree').getNodeByKey(activeNodePath)?.activate(true)
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
		@$().dynatree('getTree').getNodeByKey?(activeNodePath)?.activate(true)
	).observes('TYPO3.FormBuilder.Model.Form.currentlySelectedRenderable')
}