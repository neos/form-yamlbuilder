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

	TYPO3.FormBuilder.Model.FormDefinition.setProperties {
		identifier: 'myForm'
		pages: [
			o {
				type: 'TYPO3.Form:Page',
				identifier: 'myPage'
			}
		]
	}
), 2000);