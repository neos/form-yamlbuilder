<?php
namespace TYPO3\FormBuilder\Controller;

/*                                                                        *
 * This script belongs to the FLOW3 package "TYPO3.FormBuilder".          *
 *                                                                        *
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
	public function showAction($formPersistenceIdentifier, $presetName = NULL) {
		$this->view->assign('formPersistenceIdentifier', $formPersistenceIdentifier);
		$this->view->assign('presetName', $presetName);
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
			throw new \TYPO3\FLOW3\Exception('TODO: the template "' . $templatePath . '" was not allowed');
		}
		$form = \Symfony\Component\Yaml\Yaml::parse(file_get_contents($templatePath));

		// TODO transform to valid identifier (no spaces etc). Maybe identifier & name should be stored separately!
		$formIdentifier = $formName;
		$form['identifier'] = $formIdentifier;
		$formPersistenceIdentifier = str_replace('{identifier}', $formIdentifier, $this->settings['defaultFormPersistenceIdentifier']);
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

		// TODO transform to valid identifier (no spaces etc). Maybe identifier & name should be stored separately!
		$formIdentifier = $formName;
		$formToDuplicate['identifier'] = $formIdentifier;
		$formPersistenceIdentifier = str_replace('{identifier}', $formIdentifier, $this->settings['defaultFormPersistenceIdentifier']);
		$this->formPersistenceManager->save($formPersistenceIdentifier, $formToDuplicate);

		$this->redirect('index', 'Editor', NULL, array('formPersistenceIdentifier' => $formPersistenceIdentifier));
	}
}
?>