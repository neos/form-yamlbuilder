<?php
namespace TYPO3\FormBuilder\Controller;

/*                                                                        *
 * This script belongs to the FLOW3 package "TYPO3.FormBuilder".          *
 *                                                                        *
 *                                                                        */

use TYPO3\FLOW3\Annotations as FLOW3;

/**
 * Standard controller for the TYPO3.FormBuilder package
 *
 * @FLOW3\Scope("singleton")
 */
class SelectFormController extends \TYPO3\FLOW3\MVC\Controller\ActionController {

	/**
	 * @FLOW3\Inject
	 * @var \TYPO3\Form\Persistence\FormPersistenceManagerInterface
	 */
	protected $formPersistenceManager;

	public function indexAction() {
		$this->view->assign('newFormTemplates', $this->settings['newFormTemplates']);
		$this->view->assign('forms', $this->formPersistenceManager->listForms());
	}

	/**
	 *
	 * @param string $formName
	 * @param string $formPersistenceIdentifier
	 * @param string $templatePath
	 */
	public function createAction($formName, $formPersistenceIdentifier, $templatePath) {
		if (!isset($this->settings['newFormTemplates'][$templatePath])) {
			throw new \TYPO3\FLOW3\Exception('TODO: the template "' . $templatePath . '" was not allowed');
		}

		$form = $this->formPersistenceManager->load($templatePath, FALSE);
		$form['identifier'] = $formName;
		$this->formPersistenceManager->save($formPersistenceIdentifier, $form);

		$this->redirect('index', 'Editor', NULL, array('formPersistenceIdentifier' => $formPersistenceIdentifier));
	}
}
?>