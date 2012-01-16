<?php
namespace TYPO3\FormBuilder;

/*                                                                        *
 * This script belongs to the FLOW3 package "TYPO3.FormBuilder".          *
 *                                                                        *
 *                                                                        */

use TYPO3\FLOW3\Annotations as FLOW3;

use TYPO3\Form\Core\Model\FormDefinition;

/**
 * Standard controller for the TYPO3.FormBuilder package
 *
 */
class FormBuilderFactory extends \TYPO3\Form\Factory\AbstractFormFactory {

	public function build(array $configuration, $presetName) {
		$formDefaults = $this->getPresetConfiguration($presetName);

		$form = new FormDefinition($configuration['identifier'], $formDefaults);
		foreach ($configuration['renderables'] as $pageConfiguration) {
			$this->addNestedRenderable($pageConfiguration, $form);
		}
		return $form;
	}

	protected function addNestedRenderable($nestedRenderableConfiguration, \TYPO3\Form\Core\Model\Renderable\CompositeRenderableInterface $parentRenderable) {
		if (!isset($nestedRenderableConfiguration['identifier'])) {
			throw new \Exception('Identifier not set');
		}
		if ($parentRenderable instanceof FormDefinition) {
			$renderable = $parentRenderable->createPage($nestedRenderableConfiguration['identifier'], $nestedRenderableConfiguration['type']);
		} else {
			$renderable = $parentRenderable->createElement($nestedRenderableConfiguration['identifier'], $nestedRenderableConfiguration['type']);
		}

		if (isset($nestedRenderableConfiguration['renderables']) && is_array($nestedRenderableConfiguration['renderables'])) {
			$childRenderables = $nestedRenderableConfiguration['renderables'];
		} else {
			$childRenderables = array();
		}


		unset($nestedRenderableConfiguration['type']);
		unset($nestedRenderableConfiguration['identifier']);
		unset($nestedRenderableConfiguration['renderables']);

		$renderable->setOptions($nestedRenderableConfiguration);

		foreach ($childRenderables as $elementConfiguration) {
			$this->addNestedRenderable($elementConfiguration, $renderable);
		}

		return $renderable;
	}
}
?>