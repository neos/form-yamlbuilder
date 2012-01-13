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
		foreach ($configuration['pages'] as $pageConfiguration) {
			$this->addPage($pageConfiguration, $form);
		}
		return $form;
	}

	protected function addPage($pageConfiguration, \TYPO3\Form\Core\Model\FormDefinition $form) {
		$page = $form->createPage($pageConfiguration['identifier']);

		// TODO: implement a "setOptions" method or so!

		// TODO: nested form elements

		return $page;
	}
}
?>