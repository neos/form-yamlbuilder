<?php
namespace TYPO3\FormBuilder\ViewHelpers;

/*                                                                        *
 * This script belongs to the FLOW3 package "TYPO3.FormBuilder".          *
 *                                                                        *
 * It is free software; you can redistribute it and/or modify it under    *
 * the terms of the GNU Lesser General Public License, either version 3   *
 *  of the License, or (at your option) any later version.                *
 *                                                                        *
 * The TYPO3 project - inspiring people to share!                         *
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
	public function render($presetName = 'default') {
		$mergedConfiguration = array();

		$presetConfiguration = $this->formBuilderFactory->getPresetConfiguration($presetName);
		$supertypeResolver = new \TYPO3\Form\Utility\SupertypeResolver($presetConfiguration['formElementTypes']);
		$mergedConfiguration['formElementTypes'] = $supertypeResolver->getCompleteMergedTypeDefinition(TRUE);

		$mergedConfiguration['formElementGroups'] = isset($presetConfiguration['formElementGroups']) ? $presetConfiguration['formElementGroups'] : array();

		$stylesheets = isset($presetConfiguration['stylesheets']) ? $presetConfiguration['stylesheets'] : array();
		$mergedConfiguration['stylesheets'] = array();
		foreach ($stylesheets as $stylesheet) {
			if (isset($stylesheet['skipInFormBuilder']) && $stylesheet['skipInFormBuilder'] === TRUE) {
				continue;
			}
			$mergedConfiguration['stylesheets'][] = $this->resolveResourcePath($stylesheet['source']);
		}

		$javaScripts = isset($presetConfiguration['javaScripts']) ? $presetConfiguration['javaScripts'] : array();
		$mergedConfiguration['javaScripts'] = array();
		foreach ($javaScripts as $javaScript) {
			if (isset($javaScript['skipInFormBuilder']) && $javaScript['skipInFormBuilder'] === TRUE) {
				continue;
			}
			$mergedConfiguration['javaScripts'][] = $this->resolveResourcePath($javaScript['source']);
		}

		$mergedConfiguration['endpoints']['formPageRenderer'] = $this->controllerContext->getUriBuilder()->uriFor('renderformpage');
		$mergedConfiguration['endpoints']['loadForm'] = $this->controllerContext->getUriBuilder()->uriFor('loadform');
		$mergedConfiguration['endpoints']['saveForm'] = $this->controllerContext->getUriBuilder()->uriFor('saveform');
		$mergedConfiguration['endpoints']['editForm'] = $this->controllerContext->getUriBuilder()->uriFor('index');
		$mergedConfiguration['endpoints']['previewForm'] = $this->controllerContext->getUriBuilder()->uriFor('show', array(), 'FormManager');

		$mergedConfiguration['formPersistenceIdentifier'] = $this->controllerContext->getArguments()->getArgument('formPersistenceIdentifier')->getValue();

		$mergedConfiguration['presetName'] = $presetName;

		$availablePresets = array();
		foreach ($this->formBuilderFactory->getPresetNames() as $presetName) {
			$presetConfiguration = $this->formBuilderFactory->getPresetConfiguration($presetName);
			$availablePresets[] = array(
				'name' => $presetName,
				'title' => (isset($presetConfiguration['title']) ? $presetConfiguration['title'] : $presetName)
			);
		}
		$mergedConfiguration['availablePresets'] = $availablePresets;


		return json_encode($mergedConfiguration);
	}

	/**
	 * @param string $resourcePath
	 * @return string
	 */
	protected function resolveResourcePath($resourcePath) {
		// TODO: This method should be somewhere in the resource manager probably?
		$matches = array();
		preg_match('#resource://([^/]*)/Public/(.*)#', $resourcePath, $matches);
		if ($matches === array()) {
			throw new \TYPO3\Fluid\Core\ViewHelper\Exception('Resource path "' . $resourcePath . '" can\'t be resolved.', 1328543327);
		}
		$package = $matches[1];
		$path = $matches[2];
		return $this->resourcePublisher->getStaticResourcesWebBaseUri() . 'Packages/' . $package . '/' . $path;
	}
}
?>