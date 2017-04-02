$('#forms').find('.duplicate').click(function(event) {
	event.preventDefault();
	var $modalDuplicateForm = $('#modalDuplicateForm');
	$modalDuplicateForm.find('.formName').html($(this).data('formName'));
	$modalDuplicateForm.find('.formPersistenceIdentifier').val($(this).data('formPersistenceIdentifier'));
	$modalDuplicateForm.modal();
});