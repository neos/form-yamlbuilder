# #Class `TYPO3.FormBuilder.View.FormTree`#
#
# This class renders the hierarchical structure of the form inside a Tree View, displayed
# on top-left of the Form Builder.
#
# Its responsibilities include:
#
# - display the currently active form structure
# - activate a form element by selecting it inside the tree
# - if the form changes whatsoever, update the tree accordingly such that the tree is always up-to-date.
# - make reordering of nodes possible, taking into account pages and composite form elements.
#
# ###Reordering of Form Elements###
#
# The following constraints are ensured by the tree:
#
# - pages are only droppable before/after other pages, and not inside other form elements
# - form elements are only droppable inside other pages, before and after other form elements
# - additionally, form elements are droppable *inside* other form elements, if these target
#   form elements are composite form elements (like sections)
TYPO3.FormBuilder.View.FormTree = Ember.View.extend {
	# ***
	# ###Private###

	# shorthand to the form definition
	formDefinitionBinding: 'TYPO3.FormBuilder.Model.Form.formDefinition'

	# template name to use
	templateName: 'FormTree'

	# reference to the jQuery object containing the tree widget.
	_tree: null

	# callback being executed once the View has been rendered inside the DOM. Here, we initialize
	# the tree correctly.
	didInsertElement: ->
		@_tree = @$().find('.tree')
		@_tree.dynatree {
			# we set the currently selected renderable to the renderable being attached to the
			# currently selected tree node
			onActivate: (node) ->
				TYPO3.FormBuilder.Model.Form.set('currentlySelectedRenderable', node.data.formRenderable)

			# Drag / Drop functionality
			dnd: {
				onDragStart: -> true
				autoExpandMS: 300

				# This callback decides whether a drop target is valid and what the valid
				# drop positions are.
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

				# this callback is executed if a drop event occurs on a valid drop target.
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

		# we initialize the tree from the model
		@updateTreeStateFromModel(@_tree.dynatree('getRoot'), @getPath('formDefinition.renderables'))

		@initializeContextMenu()

	initializeContextMenu: ->
		$.contextMenu {
			selector: '#leftSidebar .tree a.dynatree-title'
			appendTo: '#leftSidebar'
			items: {
				'delete': {
					name: 'Delete'
					callback: ->
						dynaTreeNode = $(this).closest('li')[0].dtnode;
						return unless dynaTreeNode
						renderableToRemove = dynaTreeNode.data.formRenderable
						return unless renderableToRemove

						$('<div>Remove Element?</div>').dialog {
							modal: true
							resizable: false
							buttons: {
								'Delete': ->
									renderableToRemove.getPath('parentRenderable.renderables').removeObject(renderableToRemove)
									$(this).dialog('close')
								'Cancel': ->
									$(this).dialog('close')
							}
						}
				}
			}
		}

	# if a property changes, we re-draw the tree, and save the current selection on the tree and expansion state as needed.
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

	# build Tree Nodes from the form
	updateTreeStateFromModel: (dynaTreeParentNode, currentListOfSubRenderables) ->
		return if !currentListOfSubRenderables

		for subRenderable in currentListOfSubRenderables
			newNode = dynaTreeParentNode.addChild {
				key: subRenderable.get('_path')
				title: "#{if subRenderable.label then subRenderable.label else subRenderable.identifier} (#{subRenderable.getPath('typeDefinition.formBuilder.label')})"
				formRenderable: subRenderable
			}
			@updateTreeStateFromModel(newNode, subRenderable.getPath('renderables'))

	# the currently selected renderable should also be active inside the tree
	updateCurrentlySelectedNode: ( ->
		activeNodePath = TYPO3.FormBuilder.Model.Form.getPath('currentlySelectedRenderable._path')
		@_tree.dynatree('getTree').getNodeByKey?(activeNodePath)?.activate(true)
	).observes('TYPO3.FormBuilder.Model.Form.currentlySelectedRenderable')

	# callback which is triggered when the form options button is clicked.
	showFormOptions: ->
		TYPO3.FormBuilder.Model.Form.set('currentlySelectedRenderable', TYPO3.FormBuilder.Model.Form.get('formDefinition'));
}