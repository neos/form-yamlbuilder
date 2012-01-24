TYPO3.FormBuilder.View = {}

TYPO3.FormBuilder.View.AvailableFormElementsView = Ember.View.extend {
	allFormElementTypesBinding: 'TYPO3.FormBuilder.Model.FormElementTypes.allTypeNames'

	formElementsGrouped: (->
		console.log("ASDF")
		formElementsByGroup = {}

		for formElementTypeName in @get('allFormElementTypes')
			formElementType = TYPO3.FormBuilder.Model.FormElementTypes.get(formElementTypeName)
			continue unless formElementType.formBuilder?.group?
			if !formElementsByGroup[formElementType.formBuilder.group]
				formElementsByGroup[formElementType.formBuilder.group] = []

			formElementType.set('key', formElementTypeName)
			formElementsByGroup[formElementType.formBuilder.group].push(formElementType)

		formGroups = []
		for formGroupName in TYPO3.FormBuilder.Model.FormElementGroups.get('allGroupNames')
			formGroup = TYPO3.FormBuilder.Model.FormElementGroups.get(formGroupName)
			formGroup.set('key', formGroupName)
			formElementsByGroup[formGroupName]?.sort((a, b) -> a.formBuilder.sorting - b.formBuilder.sorting)
			formGroup.set('elements', formElementsByGroup[formGroupName])
			formGroups.push(formGroup)

		formGroups.sort((a, b) -> a.sorting - b.sorting)

		console.log(formGroups)
		return formGroups
	).property('allFormElementTypes').cacheable()

	templateName: 'AvailableFormElements'
}

TYPO3.FormBuilder.View.AvailableFormElementsElement = Ember.View.extend {
	tagName: 'li',
	formElementType: null
	currentlySelectedElementBinding: 'TYPO3.FormBuilder.Model.Form.currentlySelectedRenderable'

	didInsertElement: ->
		@$().html(@getPath('formElementType.formBuilder.label'))
		@$().attr('title', @getPath('formElementType.key'))
	click: ->
		el = @get('currentlySelectedElement')
		return unless el

		parentRenderablesArray = el.getPath('parentRenderable.renderables')
		indexInParent = parentRenderablesArray.indexOf(el)

		newRenderable = TYPO3.FormBuilder.Model.Renderable.create({
			type: @formElementType.get('key')
			label: '',
			identifier: Ember.generateGuid(null, 'formElement')
		})

		parentRenderablesArray.replace(indexInParent+1, 0, [newRenderable])

		@set('currentlySelectedElement', newRenderable)
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
					targetNodeIsCompositeRenderable = TYPO3.FormBuilder.Model.FormElementTypes.get(targetNode.data.formRenderable.get('type')).getPath('formBuilder.__isCompositeRenderable')

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

TYPO3.FormBuilder.View.FormElementInspector = Ember.ContainerView.extend {

	# the renderable which should be edited
	formElement: null,

	formElementType: ( ->
		formElementTypeName = @getPath('formElement.type')
		return null unless formElementTypeName

		return TYPO3.FormBuilder.Model.FormElementTypes.get(formElementTypeName)
	).property('formElement').cacheable()

	orderedFormFieldEditors: ( ->
		# copy the schema to work on a clone
		formFieldEditors = $.extend({}, @getPath('formElementType.formBuilder.formFieldEditors'))
		console.log("ffe", formFieldEditors)

		orderedFormFieldEditors = for k, v of formFieldEditors
			v['key'] = k
			v

		orderedFormFieldEditors.sort((a,b)-> a.sorting - b.sorting)
		return orderedFormFieldEditors
	).property('formElementType').cacheable()


	onFormElementChange: (->
		@removeAllChildren();
		return unless @formElement
		#formElement = @formElement

		for formFieldEditor in @get('orderedFormFieldEditors')
			subViewClass = Ember.getPath(formFieldEditor.viewName)
			throw "Editor class '#{formFieldEditor.viewName}' not found" if !subViewClass

			subViewOptions = $.extend({}, formFieldEditor, {
				formElement: @formElement
			})
			console.log(subViewOptions);
			subView = subViewClass.create(subViewOptions)
			@get('childViews').push(subView)
		@rerender()
	).observes('formElement')
}

TYPO3.FormBuilder.View.Editor = {}
TYPO3.FormBuilder.View.Editor.AbstractEditor = Ember.View.extend {
	formElement: null,
}

TYPO3.FormBuilder.View.Editor.AbstractPropertyEditor = TYPO3.FormBuilder.View.Editor.AbstractEditor.extend {
	### PUBLIC API ###
	# the property path at which the current value resides, relative to the current @formElement.
	# Required.
	propertyPath: null,

	### API FOR SUBCLASSES ###

	# if value is not set, it will be initialized with this default value.
	# this can be overridden in subclasses.
	defaultValue: '',

	# accessor for the current value
	value: ( (k, v) ->
		if v != undefined
			@formElement.setPath(@get('propertyPath'), v)
		else
			value = @formElement.getPath(@get('propertyPath'))
			if !value
				@formElement.setPathRecursively(@get('propertyPath'), @get('defaultValue'))
				value = @formElement.getPath(@get('propertyPath'))
			console.log("VAL", value)
			value
	).property('propertyPath', 'formElement').cacheable()

	# callback function which needs to be executed when the value changes
	valueChanged: ->
		@get('formElement').somePropertyChanged?(@formElement, @get('propertyPath'))

}

TYPO3.FormBuilder.View.Editor.LabelEditor = TYPO3.FormBuilder.View.Editor.AbstractEditor.extend {
	templateName: 'LabelEditor'
	label: ( (k, v) ->
		if v != undefined
			@setPath('formElement.label', v)
		else
			@getPath('formElement.label')
	).property('formElement').cacheable()
	identifier: ( (k, v)->
		if v != undefined
			@setPath('formElement.identifier', v)
		else
			@getPath('formElement.identifier')
	).property('formElement').cacheable()
}

TYPO3.FormBuilder.View.Editor.TextEditor = TYPO3.FormBuilder.View.Editor.AbstractPropertyEditor.extend {
	### PUBLIC API ###
	label: null

	onValueChange: (->
		@valueChanged()
	).observes('value')

	### PRIVATE ###
	templateName: 'TextEditor'
}
TYPO3.FormBuilder.View.Editor.PropertyGrid = TYPO3.FormBuilder.View.Editor.AbstractPropertyEditor.extend {

	### PUBLIC API ###

	# list of columns. Required.
	columns: null,

	# if TRUE, the grid is made sortable by adding a drag handle as the leftmost column
	isSortable: false,

	# if TRUE, there is always one row more inside the table which can be used to create new elements
	enableAddRow: false

	### PRIVATE ###

	defaultValue: (-> []).property().cacheable()

	# slick grid options
	options: (->
		return {
			enableColumnReorder: false
			autoHeight: true
			editable: true
			enableAddRow: @get('enableAddRow')
			enableCellNavigation: true
			asyncEditorLoading: false
			forceFitColumns: true
		}
	).property('enableAddRow').cacheable()

	# slick grid column definition
	columnDefinition: (->
		columns = []

		if @get('isSortable')
			columns.push {
				id: "#",
				name: "",
				width: 40,
				behavior: "selectAndMove",
				selectable: false,
				resizable: false,
				cssClass: "cell-reorder dnd",
				focusable: false
			}

		for column in @get('columns')
			# copy columns object as we intend to modify it.
			column = $.extend({}, column)
			column.id = column.field
			# fetch actual object for the column editor
			column.editor = Ember.getPath(column.editor)
			columns.push(column)

		return columns
	).property('columns', 'isSortable').cacheable()

	# instance of the slick grid
	grid: null

	#
	# Initialize Grid
	#
	didInsertElement: ->
		@grid = new Slick.Grid(@$(), @get('value'), @get('columnDefinition'), @get('options'));

		# make autoHeight really work
		@$().find('.slick-viewport').css('overflow-x', 'hidden');
		@$().find('.slick-viewport').css('overflow-y', 'hidden');
		@grid.setSelectionModel(new Slick.RowSelectionModel());

		# Save changes to cells
		@grid.onCellChange.subscribe (e, args) =>
			@get('value').replace(args.row, 1, args.item)
			@valueChanged()

		# add new rows
		@grid.onAddNewRow.subscribe (e, args) =>
			@grid.invalidateRow(@get('value').length);

			# ... initialize all columns to empty string values
			newItem = {}
			newItem[columnDefinition.field] = '' for columnDefinition in @columns
			$.extend(newItem, args.item)
			@get('value').push(newItem)

			@grid.updateRowCount()
			@grid.render()
			@valueChanged()

		# move rows via drag/drop
		moveRowsPlugin = new Slick.RowMoveManager()
		@grid.registerPlugin(moveRowsPlugin);

		moveRowsPlugin.onBeforeMoveRows.subscribe (e, data) ->
			for i in [0...data.rows.length]
				# no point in moving before or after itself
				if data.rows[i] == data.insertBefore || data.rows[i] == data.insertBefore - 1
					e.stopPropagation();
					return false;
			return true

		moveRowsPlugin.onMoveRows.subscribe (e, args) =>
			# args.insertBefore contains index before which the element should be inserted
			# args.rows contains the indices of the moved rows (we only support one moved row at a time)
			movedRowIndex = args.rows[0]
			arrayRowToBeMoved = @get('value').objectAt(movedRowIndex)
			@get('value').removeAt(movedRowIndex, 1)

			if movedRowIndex < args.insertBefore
				# we removed the element before, thus we need decrement the pointer where the new code should be inserted
				args.insertBefore--
			@get('value').insertAt(args.insertBefore, arrayRowToBeMoved)
			@valueChanged()

			@grid.invalidateAllRows();
			@grid.render()
}




#
# Render the current page of the form server-side
#
TYPO3.FormBuilder.View.FormPageView = Ember.View.extend {
	formPagesBinding: 'TYPO3.FormBuilder.Model.Form.formDefinition.renderables',
	currentPageIndex: 0

	currentAjaxRequest: null,

	page: Ember.computed(->
		@get('formPages')?.get(@get('currentPageIndex'))
	).property('formPages', 'currentPageIndex').cacheable()

	renderPageIfPageObjectChanges: (->
		if (!TYPO3.FormBuilder.Model.Form.get('formDefinition')?.get('identifier'))
			return
		if @currentAjaxRequest
			@currentAjaxRequest.abort()

		window.setTimeout( =>
			formDefinition = TYPO3.FormBuilder.Utility.convertToSimpleObject(TYPO3.FormBuilder.Model.Form.get('formDefinition'))
			console.log("POST DATA" )
			@currentAjaxRequest = $.post(
				TYPO3.FormBuilder.Configuration.endpoints.formPageRenderer,
				{ formDefinition },
				(data, textStatus, jqXHR) =>
					#return unless @currentAjaxRequest == jqXHR
					this.$().html(data);
					@postProcessRenderedPage();
			)
		, 300)

	).observes('page', 'page.__nestedPropertyChange'),

	postProcessRenderedPage: ->
		this.$().find('fieldset').addClass('typo3-form-sortable').sortable {
			revert: 'true'
		};
}