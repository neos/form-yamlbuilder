<?php
namespace TYPO3\FormBuilder\ViewHelpers;

/*                                                                        *
 * This script belongs to the FLOW3 package "TYPO3.FormBuilder".          *
 *                                                                        *
 *                                                                        */

use TYPO3\FLOW3\Annotations as FLOW3;

/**
 * @todo rename
 */
class JsonConfigurationViewHelper extends \TYPO3\Fluid\Core\ViewHelper\AbstractViewHelper {

	/**
	 * @FLOW3\Inject
	 * @var \TYPO3\FormBuilder\FormBuilderFactory
	 */
	protected $formBuilderFactory;

	/**
	 * @param string $presetName
	 * @return type
	 */
	public function render($presetName = 'Default') {
		$configuration = array();

		$presetConfiguration = $this->formBuilderFactory->getPresetConfiguration($presetName);
		$supertypeResolver = new \TYPO3\Form\Utility\SupertypeResolver($presetConfiguration['formElementTypes']);
		$configuration['formElementTypes'] = $supertypeResolver->getCompleteMergedTypeDefinition(TRUE);

		$configuration['formElementGroups'] = isset($presetConfiguration['formElementGroups']) ? $presetConfiguration['formElementGroups'] : array();

		$configuration['endpoints']['formPageRenderer'] = $this->controllerContext->getUriBuilder()->uriFor('renderformpage');

		return json_encode($configuration);
	}
}
?>