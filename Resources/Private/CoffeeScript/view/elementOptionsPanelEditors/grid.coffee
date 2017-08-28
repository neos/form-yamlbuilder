# <!--
# This file is part of the Neos.Form.YamlBuilder package.
#
# (c) Contributors of the Neos Project - www.neos.io
#
# This package is Open Source Software. For the full copyright and license
# information, please view the LICENSE file which was distributed with this
# source code.
# -->


# #Namespace `Neos.Form.YamlBuilder.View.Editor`#
#
# This file implements the `Property Grid` editor.
#
# ##Class Editor.PropertyGrid##
#
# This editor makes a collection of properties editable, supports the following features:
#
# - arbitrary number of columns
# - columns are made sortable if wanted
# - a new column is added at the bottom to insert a new element
Neos.Form.YamlBuilder.View.ElementOptionsPanel.Editor.PropertyGrid = Neos.Form.YamlBuilder.View.ElementOptionsPanel.Editor.AbstractPropertyEditor.extend {

	# ###Public API###
	#
	# - `columns`: Array of column definition objects, where each object needs at least:
	#    - `field`: Field name of the column
	#    - `editor`: Editor name
	#    - [any other SlickGrid Column Option]: You can override any other SlickGrid column option here
	columns: null,

	# - `isSortable`: if TRUE, the grid is made sortable by adding a drag handle as the leftmost column
	isSortable: false,

	# - `enableAddRow`: if TRUE, there is always one row more inside the table which can be used to create new elements
	enableAddRow: false

	# - `enableDeleteRow`: if TRUE, the last row with a delete icon is added
	enableDeleteRow: false

	# - `shouldShowPreselectedValueColumn`: (false|'single'|'multiple'). If set, then a column for setting the defaultValue
	#   on the Form Element is shown.
	#
	#   By setting it to "single", setting the preselected value on one element will de-select all other elements. This is suitable
	#   for radioboxes or single-select boxes.
	#
	#   By setting it to "multiple", multiple pre-selected values are supported. This is suitable for multi-select and checkboxes.
	#
	#   NOTE: When using this feature, the system *expects* a column called _key which will be used to get/set the default value then.
	shouldShowPreselectedValueColumn: false

	# ***
	# ###Private###
	templateName: 'ElementOptionsPanel-PropertyGridEditor'
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

		if @get('shouldShowPreselectedValueColumn')
			columns.push {
				id: '__preselectedValues'
				field: '__isPreselected'
				name: 'Selected'
				selectable: false
				resizable: false
				formatter: YesNoCellFormatter
				editor: YesNoCheckboxCellEditor
			}

		if @get('enableDeleteRow')
			columns.push {
				id: '__delete'
				name: '',
				width: 16
				selectable: false
				resizable: false
				focusable: false
				cssClass: "neos-form-yamlbuilder-grid-deleteRow"
			}

		return columns
	).property('columns', 'isSortable').cacheable()

	# slick grid table rows (is a computed property because we might need to take
	# sorting etc into account)
	tableRowModel: null,

	buildTableRowModel: (->

		@set('tableRowModel', []) unless @get('tableRowModel')
		tableRowModel = @get('tableRowModel')
		# clear out complete table row model if necessary
		tableRowModel.removeAt(0, tableRowModel.get('length')) if tableRowModel.get('length') > 0

		if @get('shouldShowPreselectedValueColumn') == 'multiple'
			defaultValue = @getPath('formElement.defaultValue')  || []
		else if @get('shouldShowPreselectedValueColumn') == 'single' && @getPath('formElement.defaultValue')
			defaultValue = [@getPath('formElement.defaultValue')]
		else
			defaultValue = []

		for originalRow in @get('value')
			isPreselected = false
			for v in defaultValue
				if (v == originalRow._key)
					isPreselected = true

			tableRowModel.push($.extend({__isPreselected: isPreselected}, originalRow))
	)

	valueChanged: ->
		# here, we split the row model into the "rows" and the "default value" array,
		# as these need to be processed seperately.
		rows = []
		defaultValue = [];
		for tableRowModelRow in @get('tableRowModel')
			if tableRowModelRow.__isPreselected
				defaultValue.push(tableRowModelRow._key)
			tmp = $.extend({}, tableRowModelRow)
			delete tmp.__isPreselected
			rows.push(tmp)

		# now, after the split, update default value and rows
		if @get('shouldShowPreselectedValueColumn') == 'multiple'
			@setPath('formElement.defaultValue', defaultValue)
			@set('value', rows)
		else if @get('shouldShowPreselectedValueColumn') == 'single'
			@set('value', rows)

			# Default value handling is a little complex here, as we need to
			# determine how the default value has changed by comparing the
			# defaultValue array with the old default value.
			if (defaultValue.length == 0)
				# no default value selected at all, thus we can remove the default value
				@setPath('formElement.defaultValue', null)
			else
				# default value has been selected; we only change the
				# default value in case it is different from the old one.
				oldDefaultValue = @getPath('formElement.defaultValue')
				for v, i in defaultValue
					if v != oldDefaultValue
						@setPath('formElement.defaultValue', v)

			# after setting value and default value, we need to completely re-draw
			# the table.
			@buildTableRowModel()
			@grid.invalidateAllRows()
			@grid.render()
		else
			@set('value', rows)
		@_super()

	# instance of the slick grid
	grid: null

	init: ->
		@classNames.push('PropertyGrid')
		@_super()

	# Initialize Grid
	didInsertElement: ->
		@buildTableRowModel()
		@grid = new Slick.Grid(@$().find('.neos-form-yamlbuilder-grid'), @get('tableRowModel'), @get('columnDefinition'), @get('options'));

		# make autoHeight really work
		@$().find('.slick-viewport').css('overflow-x', 'hidden');
		@$().find('.slick-viewport').css('overflow-y', 'hidden');
		@grid.setSelectionModel(new Slick.RowSelectionModel());

		# as soon as drag and drop starts, commit the current edit (else, drag/drop won't work)
		@grid.onDragInit.subscribe => @grid.getEditorLock().commitCurrentEdit()

		# Save changes to cells
		@grid.onCellChange.subscribe (e, args) =>
			@get('tableRowModel').replace(args.row, 1, args.item)
			@valueChanged()

		# add new rows
		@grid.onAddNewRow.subscribe (e, args) =>
			@grid.invalidateRow(@get('tableRowModel').length);

			# ... initialize all columns to empty string values
			newItem = {}
			newItem[columnDefinition.field] = '' for columnDefinition in @columns
			$.extend(newItem, args.item)
			@get('tableRowModel').pushObject(newItem)

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
			arrayRowToBeMoved = @get('tableRowModel').objectAt(movedRowIndex)
			@get('tableRowModel').removeAt(movedRowIndex, 1)

			if movedRowIndex < args.insertBefore
				# we removed the element before, thus we need decrement the pointer where the new code should be inserted
				args.insertBefore--
			@get('tableRowModel').insertAt(args.insertBefore, arrayRowToBeMoved)
			@valueChanged()

			@grid.invalidateAllRows();
			@grid.render()

		# delete row handling
		if @get('enableDeleteRow')
			@grid.onClick.subscribe( (e, args) =>
				if @get('enableDeleteRow') && args.cell == @get('columnDefinition').length - 1
					# delete row is enabled, and by convention, it is the last row...
					# and the user clicked onto the last row, i.e. we need to remove it.
					return if args.row >= @getPath('tableRowModel.length') # user clicked on the "add row"

					@get('tableRowModel').removeAt(args.row)
					@grid.invalidateAllRows()
					@grid.render()
					@grid.resizeCanvas()
					@valueChanged()
			)
}

# This is just a standard TextCellEditor of SlickGrid; extended in a way that when
# defocussing the text field, the edit is committed / saved.
Neos.Form.YamlBuilder.View.ElementOptionsPanel.Editor.PropertyGrid.TextCellEditor = (args) ->
	retVal = window.TextCellEditor.apply(this, arguments)

	$(args.container).children('.editor-text').focusout ->
		Slick.GlobalEditorLock.commitCurrentEdit()

	return retVal
