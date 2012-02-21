<?php
namespace TYPO3\FormBuilder\Controller;

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
 * Form Manager controller for the TYPO3.FormBuilder package
 *
 * @FLOW3\Scope("singleton")
 */
class FormManagerController extends \TYPO3\FLOW3\MVC\Controller\ActionController {

	/**
	 * @FLOW3\Inject
	 * @var \TYPO3\Form\Persistence\FormPersistenceManagerInterface
	 */
	protected $formPersistenceManager;

	/**
	 * The settings of the TYPO3.Form package
	 *
	 * @var array
	 * @api
	 */
	protected $formSettings;

	/**
	 * @FLOW3\Inject
	 * @var \TYPO3\FLOW3\Configuration\ConfigurationManager
	 * @internal
	 */
	protected $configurationManager;

	/**
	 * @internal
	 */
	public function initializeObject() {
		$this->formSettings = $this->configurationManager->getConfiguration(\TYPO3\FLOW3\Configuration\ConfigurationManager::CONFIGURATION_TYPE_SETTINGS, 'TYPO3.Form');
	}

	/**
	 * Displays the Form Manager in all its glory
	 *
	 * @return void
	 */
	public function indexAction() {
		$this->view->assign('newFormTemplates', $this->settings['newFormTemplates']);
		$this->view->assign('forms', $this->formPersistenceManager->listForms());
	}

	/**
	 * Previews one form
	 *
	 * @param string $formPersistenceIdentifier
	 * @param string $presetName
	 * @return void
	 */
	public function showAction($formPersistenceIdentifier, $presetName = 'default') {
		$this->view->assign('formPersistenceIdentifier', $formPersistenceIdentifier);
		$this->view->assign('presetName', $presetName);
		$availablePresets = array();
		foreach ($this->formSettings['presets'] as $presetName => $presetConfiguration) {
			$availablePresets[$presetName] = isset($presetConfiguration['title']) ? $presetConfiguration['title'] : sprintf('[%s]', $presetName);
		}
		$this->view->assign('availablePresets', $availablePresets);
	}

	/**
	 * Creates a new Form and redirects to the Form Editor
	 *
	 * @param string $formName
	 * @param string $templatePath
	 * @return void
	 */
	public function createAction($formName, $templatePath) {
		if (!isset($this->settings['newFormTemplates'][$templatePath])) {
			throw new \TYPO3\FLOW3\Exception(sprintf('The template path "%s" is not allowed', $templatePath), 1329233410);
		}
		$form = \Symfony\Component\Yaml\Yaml::parse(file_get_contents($templatePath));
		$form['label'] = $formName;
		$formIdentifier = $this->convertFormNameToIdentifier($formName);;
		$form['identifier'] = $formIdentifier;

		$formPersistenceIdentifier = $this->findUniquePersistenceIdentifier($formIdentifier);
		$this->formPersistenceManager->save($formPersistenceIdentifier, $form);

		$this->redirect('index', 'Editor', NULL, array('formPersistenceIdentifier' => $formPersistenceIdentifier));
	}

	/**
	 * Duplicates a given Form and redirects to the Form Editor
	 *
	 * @param string $formName
	 * @param string $formPersistenceIdentifier persistence identifier of the form to duplicate
	 * @return void
	 */
	public function duplicateAction($formName, $formPersistenceIdentifier) {
		$formToDuplicate = $this->formPersistenceManager->load($formPersistenceIdentifier);
		$formToDuplicate['label'] = $formName;
		$formToDuplicate['identifier'] = $this->convertFormNameToIdentifier($formName);

		$formPersistenceIdentifier = $this->findUniquePersistenceIdentifier($formToDuplicate['identifier']);
		$this->formPersistenceManager->save($formPersistenceIdentifier, $formToDuplicate);

		$this->redirect('index', 'Editor', NULL, array('formPersistenceIdentifier' => $formPersistenceIdentifier));
	}

	/**
	 * @param string $formName
	 * @return string the form identifier which is the lowerCamelCased form name
	 */
	protected function convertFormNameToIdentifier($formName) {
		$formIdentifier = preg_replace('/[^a-zA-Z0-9-_]/', '', lcfirst($formName));
		if (preg_match(\TYPO3\Form\Core\Model\FormElementInterface::PATTERN_IDENTIFIER, $formIdentifier) !== 1) {
			$this->addFlashMessage('The form name "%s" is not allowed', 'Invalid form name', \TYPO3\FLOW3\Error\Message::SEVERITY_ERROR, array($formName));
			$this->redirect('index');
		}
		return $formIdentifier;
	}

	/**
	 * This takes a form identifier and returns a unique persistence identifier for it.
	 * By default this is just similar to the identifier. But if a form with the same persistence identifier already
	 * exists a suffix is appended until the persistence identifier is unique.
	 *
	 * @param string $formIdentifier lowerCamelCased form identifier
	 * @return string unique form persistence identifier
	 */
	protected function findUniquePersistenceIdentifier($formIdentifier) {
		if (!$this->formPersistenceManager->exists($formIdentifier)) {
			return $formIdentifier;
		}
		for ($attempts = 1; $attempts < 100; $attempts ++) {
			$formPersistenceIdentifier = sprintf('%s_%d', $formIdentifier, $attempts);
			if (!$this->formPersistenceManager->exists($formPersistenceIdentifier)) {
				return $formPersistenceIdentifier;
			}
		}
		throw new \TYPO3\FLOW3\Exception(sprintf('Could not find a unique persistence identifier for form identifier "%s" after %d attempts', $formIdentifier, $attempts), 1329842768);
	}
}
?>