TYPO3.FormBuilder.View = {}

TYPO3.FormBuilder.View.AvailableFormElementsView = Ember.CollectionView.extend {
	contentBinding: 'TYPO3.FormBuilder.Model.AvailableFormElements.content'

	itemViewClass: Ember.View.extend {
		templateName: 'item'
		didInsertElement: ->
			this.$().draggable {
				connectToSortable: '.typo3-form-sortable'
				helper: ->
					$('<div>' + $(this).html() + '</div>')
				revert: 'invalid'
			}
	}
}

#
# Structure of the form
#
TYPO3.FormBuilder.View.FormStructure = Ember.View.extend {
	formDefinitionBinding: 'TYPO3.FormBuilder.Model.Form.formDefinition'
	didInsertElement: ->
		@$().dynatree {
			onActivate: (node)->
				TYPO3.FormBuilder.Model.Form.set('currentlySelectedRenderable', node.data.formRenderable)
			dnd: {
				onDragStart: -> true
				autoExpandMS: 300
				onDragEnter: (targetNode, sourceNode) ->
					targetNodeIsCompositeRenderable = TYPO3.FormBuilder.Model.FormElementTypes.get("#{targetNode.data.formRenderable.get('type')}._isCompositeRenderable")

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
}

TYPO3.FormBuilder.View.FormElementInspector = Ember.View.extend {
	templateName: 'formElementInspector'

	formElementBinding: 'TYPO3.FormBuilder.Model.Form.currentlySelectedRenderable'
	formElementType: ( ->
		formElementTypeName = @getPath('formElement.type')

		return null if !formElementTypeName

		return TYPO3.FormBuilder.Model.FormElementTypes.get(formElementTypeName)
	).property('formElement', 'formElement.type').cacheable()
}

TYPO3.FormBuilder.View.FormElementInspectorPart = Ember.ContainerView.extend {
	formElement: null,

	# the value which should be edited
	propertyPath: null,

	# the schema which describes how Value should be edited
	schema: null

	orderedSchema: ( ->
		# copy the schema to work on a clone
		schema = $.extend({}, @get('schema'))

		orderedSchema = for k, v of schema
			v['key'] = k
			v

		orderedSchema.sort((a,b)-> a.sorting - b.sorting)
		return orderedSchema
	).property('schema').cacheable()

	render: ->
		return unless @formElement
		formElement = @formElement

		for schemaElement in @get('orderedSchema')
			console.log(schemaElement)
			subViewClass = Ember.getPath(schemaElement.viewName)
			throw "Editor class '#{schemaElement.viewName}' not found" if !subViewClass

			pathToCurrentValue = @propertyPath + '.' + schemaElement.key

			subViewOptions = $.extend({}, schemaElement.viewOptions, {
				_pathToCurrentValue: pathToCurrentValue
				value: formElement.getPath(pathToCurrentValue)
				changed: ->
					formElement.setPath(@_pathToCurrentValue, @value)
					formElement.somePropertyChanged(formElement, @_pathToCurrentValue)
			})

			@appendChild(subViewClass.create(subViewOptions))

		@_super()

	onFormElementChange: (->
		this.rerender()
	).observes('formElement')
}

TYPO3.FormBuilder.View.Editor = {}
TYPO3.FormBuilder.View.Editor.AbstractEditor = Ember.View.extend {
	value: null,
	changed: Ember.K
}
TYPO3.FormBuilder.View.Editor.PropertyGrid = TYPO3.FormBuilder.View.Editor.AbstractEditor.extend {

	columns: null,
	options: {
		enableColumnReorder: false,
		autoHeight: true

		editable: true,
		enableAddRow: true,
		enableCellNavigation: true,
		asyncEditorLoading: false
	},

	grid: null

	didInsertElement: ->
		@grid = new Slick.Grid(@$(), @value, @columns, @options);
		@grid.setSelectionModel(new Slick.CellSelectionModel());
		@grid.onCellChange.subscribe (e, args) =>
			@value.replace(args.row, 1, args.item)
			@changed()

		@grid.onAddNewRow.subscribe (e, args) =>
			@grid.invalidateRow(@value.length);

			newItem = {}
			newItem[columnDefinition.field] = '' for columnDefinition in @columns
			$.extend(newItem, args.item)
			console.log("add new row", newItem);
			@value.push(newItem)
			console.log(@value)

			@grid.updateRowCount()
			@grid.render();
			@changed()

#			@value.push(newItem)
#			@changed()
#			@grid.updateRowCount();
#			@grid.render();
#		@grid.onCellChange.subscribe (e, args) =>
#			item = args.item
#			@grid.invalidateRow(
#
#			@changed()
}




#
# Render the current page of the form server-side
#
TYPO3.FormBuilder.View.FormPageView = Ember.View.extend {
	formPagesBinding: 'TYPO3.FormBuilder.Model.Form.formDefinition.renderables',
	currentPageIndex: 0

	page: Ember.computed(->
		@get('formPages')?.get(@get('currentPageIndex'))
	).property('formPages', 'currentPageIndex').cacheable()

	renderPageIfPageObjectChanges: (->
		if (!TYPO3.FormBuilder.Model.Form.get('formDefinition')?.get('identifier'))
			return
		formDefinition = TYPO3.FormBuilder.Utility.convertToSimpleObject(TYPO3.FormBuilder.Model.Form.get('formDefinition'))
		console.log("POST DATA" )
		$.post(
			TYPO3.FormBuilder.Configuration.endpoints.formPageRenderer,
			{ formDefinition },
			(data) =>
				this.$().html(data);
				@postProcessRenderedPage();
		)
	).observes('page', 'page.__nestedPropertyChange'),

	postProcessRenderedPage: ->
		this.$().find('fieldset').addClass('typo3-form-sortable').sortable {
			revert: 'true'
		};
}