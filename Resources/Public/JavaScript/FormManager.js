$('#forms .duplicate').click(function(event) {
	event.preventDefault();
	$('#modalDuplicateForm .formName').html($(this).data('formName'));
	$('#modalDuplicateForm .formPersistenceIdentifier').val($(this).data('formPersistenceIdentifier'));
	$('#modalDuplicateForm').modal();
});