TYPO3.FormBuilder.View = {}

TYPO3.FormBuilder.View.AvailableFormElementsView = Ember.CollectionView.extend {
	contentBinding: 'TYPO3.FormBuilder.Model.AvailableFormElements.content'
	click: -> console.log('click')

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
		@$().dynatree('getTree').visit (node) ->
			if (node.isExpanded())
				expandedNodePaths.push(node.data.key)

		activeNodePath = @$().dynatree('getActiveNode')?.data.key

		@$().dynatree('getRoot').removeChildren?()
		@updateTreeStateFromModel(@$().dynatree('getRoot'), @getPath('formDefinition.renderables'))

		for expandedNodePath in expandedNodePaths
			@$().dynatree('getTree').getNodeByKey(expandedNodePath).expand(true)


		@$().dynatree('getTree').getNodeByKey(activeNodePath)?.activate(true)
	).observes('formDefinition.__nestedPropertyChange')

	updateTreeStateFromModel: (dynaTreeParentNode, currentListOfSubRenderables) ->
		if (!currentListOfSubRenderables)
			return
		for subRenderable in currentListOfSubRenderables
			newNode = dynaTreeParentNode.addChild {
				key: subRenderable.get('_path')
				title: if subRenderable.label then subRenderable.label else subRenderable.identifier
				formRenderable: subRenderable
			}
			@updateTreeStateFromModel(newNode, subRenderable.getPath('renderables'))
}

TYPO3.FormBuilder.View.FormElementStructure = Ember.View.extend {
	currentlySelectedRenderableBinding: 'TYPO3.FormBuilder.Model.Form.currentlySelectedRenderable'
	templateName: 'formElementStructure'
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


TYPO3.FormBuilder.View.PropertyPanelPart = Ember.CollectionView.extend {
	# the current renderable
	renderable: null,
	# the current property key
	propertyKey: null,

	propertySchemaKey: null

	foo: (->
		console.log("RD ch", @get('renderable'))
	).observes('renderable')
	# is an array of schema entries, ordered by "order"
	currentlyActiveSchema: (->
		formElementTypeName = @getPath('renderable.type')
		console.log(formElementTypeName)
		return [] if !formElementTypeName

		formElementType = TYPO3.FormBuilder.Model.FormElementTypes.get(formElementTypeName)
		console.log(formElementType)
		return [] if !formElementType

		unprocessedSchema = formElementType.get(@get('propertySchemaKey'))

		unprocessedSchema = $.extend({}, unprocessedSchema);
		schema = for k, v of unprocessedSchema
			v['key'] = k
			v.getValue = =>
				@renderable.get(@propertyKey)[k]
			v.setValue = (newValue) =>
				@renderable.get(@propertyKey)[k] = newValue
				@renderable.somePropertyChanged(@renderable, "#{@propertyKey}.#{k}")
			v

		schema.sort((a,b)-> a.sorting - b.sorting)
		console.log(schema)
		return schema
	).property('renderable', 'propertySchemaKey', 'propertyKey').cacheable()

	contentBinding: 'currentlyActiveSchema',

	click: -> console.log('click')

	itemViewClass: Ember.View.extend {
		templateName: 'property-panel-part-item'
	}
}

TYPO3.FormBuilder.View.PropertyPanelPartEditor = SC.ContainerView.extend {
	propertySchema: null,

	render: ->
		return if !@propertySchema

		subViewClass = Ember.getPath(@propertySchema.viewName)

		if !subViewClass
			throw "Editor class '#{@propertySchema.viewName}' not found"

		subViewOptions = $.extend({
			propertySchemaBinding: 'parentView.propertySchema'
		}, @propertySchema.viewOptions)

		subView = subViewClass.create(subViewOptions)


		@appendChild(subView)
		@_super()

#		var editorConfigurationDefinition = typeDefinition;
#		if (this.propertyDefinition.userInterface && this.propertyDefinition.userInterface) {
#			editorConfigurationDefinition = $.extend({}, editorConfigurationDefinition, this.propertyDefinition.userInterface);
#		}
#
#		var editorClass = SC.getPath(editorConfigurationDefinition['class']);
#		if (!editorClass) {
#			throw 'Editor class "' + typeDefinition['class'] + '" not found';
#		}
#
#		var classOptions = $.extend({
#			valueBinding: 'T3.Content.Controller.Inspector.blockProperties.' + this.propertyDefinition.key
#
#		}, this.propertyDefinition.options || {});
#		classOptions = $.extend(classOptions, typeDefinition.options || {});
#
#		var editor = editorClass.create(classOptions);
#		this.appendChild(editor);
#		this._super();
}


TYPO3.FormBuilder.View.Editor = {}
TYPO3.FormBuilder.View.Editor.PropertyGrid = Ember.View.extend {
	templateName: 'PropertyGrid'
	propertySchema: null,

	columns: null,
	options: {
		enableCellNavigation: false,
		enableColumnReorder: false,
		autoHeight: true
	},

	value: ((key, newValue) ->
		if newValue
			@propertySchema.setValue(newValue)
		else
			@propertySchema.getValue()
	).property('propertySchema').cacheable()

	grid: null

	didInsertElement: ->
		console.log("VAL: ", @get('value'))
		@grid = new Slick.Grid(@$(), @get('value'), @get('columns'), @get('options'));
}