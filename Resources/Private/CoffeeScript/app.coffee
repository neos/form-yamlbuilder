TYPO3 = window.TYPO3 || {}
window.TYPO3 = TYPO3


TYPO3.FormBuilder = Ember.Application.create {
	rootElement: 'body'
}
TYPO3.FormBuilder.Configuration = window.FORMBUILDER_CONFIGURATION


window.setTimeout((->

	TYPO3.FormBuilder.Model.Form.set('formDefinition', TYPO3.FormBuilder.Model.Renderable.create {
		identifier: 'myForm'
		renderables: [
			{
				type: 'TYPO3.Form:Page',
				identifier: 'myPage',
				label: 'My Page 1'
				renderables: [
					{
						identifier: 'foobarbaz'
						type: 'TYPO3.Form:Textfield',
						label: 'My Label'
					}
					{
						identifier: 'foobarbaz2'
						type: 'TYPO3.Form:Textfield',
						label: 'My Label'
					}
					{
						identifier: 'gender'
						type: 'TYPO3.Form:Radiobuttons',
						label: 'Gender'
						properties: {
							options: [
								{
									_key: 'm'
									_value: 'Male'
								}
								{
									_key: 'f'
									_value: 'Female'
								}
							]
						}
					}
				]
			}
			{
				type: 'TYPO3.Form:Page',
				identifier: 'myPage2',
				label: ''
			}
		],

	})
), 2000);