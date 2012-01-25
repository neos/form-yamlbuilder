# #Main Base Class#
# Main Entry for the form builder, setting up the environment and initializing
# `TYPO3.FormBuilder` namespace.
#

TYPO3 = window.TYPO3 || {}
window.TYPO3 = TYPO3

# `TYPO3.FormBuilder` is the namespace where the whole package is inside
TYPO3.FormBuilder = Ember.Application.create {
	rootElement: 'body'
}
# `TYPO3.FormBuilder.Configuration` contains the server-side generated config array.
TYPO3.FormBuilder.Configuration = window.FORMBUILDER_CONFIGURATION

if TYPO3.FormBuilder.Configuration.cssFiles
	for cssFile in TYPO3.FormBuilder.Configuration.cssFiles
		$('head').append($('<link rel="stylesheet" />').attr('href', cssFile))

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