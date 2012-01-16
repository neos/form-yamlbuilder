TYPO3 = window.TYPO3 || {}
window.TYPO3 = TYPO3


TYPO3.FormBuilder = Ember.Application.create {
	rootElement: 'body'
}
TYPO3.FormBuilder.Configuration = window.FORMBUILDER_CONFIGURATION


window.setTimeout((->
	TYPO3.FormBuilder.Model.AvailableFormElements.set('content', [{
		type: 'TYPO3.Form:Textbox'
		label: 'Text Box'
	},{
		type: 'TYPO3.Form:Textfield'
		label: 'Text Field'
	}])

	# Helper function which wraps a JSON object into an Ember Object
	o = (obj) -> Ember.Object.create(obj)
	r = (obj) -> TYPO3.FormBuilder.Model.Renderable.create(obj)


	TYPO3.FormBuilder.Model.Form.set('formDefinition', TYPO3.FormBuilder.Model.Renderable.create {
		identifier: 'myForm'
		renderables: [
			{
				type: 'TYPO3.Form:Page',
				identifier: 'myPage'
				renderables: [
					{
						identifier: 'foobarbaz'
						type: 'TYPO3.Form:Textfield',
						label: 'My Label'
					}
				]
			}
			{
				type: 'TYPO3.Form:Page',
				identifier: 'myPage2',
			}
		],

	})

	#TYPO3.FormBuilder.Model.FormDefinition.get('renderables').removeAt(0);
	window.setTimeout(->
		#TYPO3.FormBuilder.Model.Form.setPath('formDefinition.renderables.0.renderables.0.label', 'My other label');
		console.log(TYPO3.FormBuilder.Utility.convertToSimpleObject(TYPO3.FormBuilder.Model.Form.get('formDefinition')));
	,2000);
), 2000);