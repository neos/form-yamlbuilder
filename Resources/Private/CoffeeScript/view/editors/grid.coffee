# #Namespace `TYPO3.FormBuilder.View.Editor`#
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
TYPO3.FormBuilder.View.Editor.PropertyGrid = TYPO3.FormBuilder.View.Editor.AbstractPropertyEditor.extend {

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

	# ***
	# ###Private###
	templateName: 'PropertyGridEditor'
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

	init: ->
		@classNames.push('PropertyGrid')
		@_super()

	# Initialize Grid
	didInsertElement: ->
		@grid = new Slick.Grid(@$().find('.grid'), @get('value'), @get('columnDefinition'), @get('options'));

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
			@get('value').pushObject(newItem)

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

