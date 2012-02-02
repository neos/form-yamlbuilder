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
	 * @var \TYPO3\FLOW3\Resource\Publishing\ResourcePublisher
	 */
	protected $resourcePublisher;

	/**
	 * @FLOW3\Inject
	 * @var \TYPO3\Form\Factory\ArrayFormFactory
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

		$configuration['cssFiles'] = isset($presetConfiguration['cssFiles']) ? $this->resolveCssFiles($presetConfiguration['cssFiles']) : array();

		$configuration['endpoints']['formPageRenderer'] = $this->controllerContext->getUriBuilder()->uriFor('renderformpage');
		$configuration['endpoints']['loadForm'] = $this->controllerContext->getUriBuilder()->uriFor('loadform');
		$configuration['endpoints']['saveForm'] = $this->controllerContext->getUriBuilder()->uriFor('saveform');

		$configuration['formPersistenceIdentifier'] = $this->controllerContext->getArguments()->getArgument('formPersistenceIdentifier')->getValue();

		return json_encode($configuration);
	}

	protected function resolveCssFiles(array $cssFiles) {
		$processedCssFiles = array();
		foreach ($cssFiles as $cssFile) {
			// TODO: This method should be somewhere in the resource manager probably?
			if (preg_match('#resource://([^/]*)/Public/(.*)#', $cssFile, $matches) > 0) {
				$package = $matches[1];
				$path = $matches[2];

				$processedCssFiles[] = $this->resourcePublisher->getStaticResourcesWebBaseUri() . 'Packages/' . $package . '/' . $path;

			} else {
				$processedCssFiles[] = $cssFile;
			}
		}
		return $processedCssFiles;
	}
}
?>