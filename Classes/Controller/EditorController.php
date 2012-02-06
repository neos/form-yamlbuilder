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
class EditorController extends \TYPO3\FLOW3\MVC\Controller\ActionController {

	/**
	 * @FLOW3\Inject
	 * @var \TYPO3\Form\Persistence\FormPersistenceManagerInterface
	 */
	protected $formPersistenceManager;

	/**
	 * Displays the example form
	 *
	 * @param string $formPersistenceIdentifier
	 * @return void
	 */
	public function indexAction($formPersistenceIdentifier) {
		$handlebarsTemplates = array();
		foreach ($this->settings['handlebarsTemplates'] as $templateName => $filePath) {
			$handlebarsTemplates[] = '<script type="text/x-handlebars" data-template-name="' . $templateName . '">' . file_get_contents($filePath) . '</script>';
		}

		$this->view->assign('handlebarsTemplates', implode("\n", $handlebarsTemplates));
	}

	/**
	 * @param string $formPersistenceIdentifier
	 * @return array
	 */
	public function loadformAction($formPersistenceIdentifier) {
		return json_encode($this->formPersistenceManager->load($formPersistenceIdentifier));
	}

	/**
	 * @param string $formPersistenceIdentifier
	 * @param array $formDefinition
	 */
	public function saveformAction($formPersistenceIdentifier, array $formDefinition) {
		$this->formPersistenceManager->save($formPersistenceIdentifier, $formDefinition);
	}

	/**
	 * @param array $formDefinition
	 * @param integer $currentPageIndex
	 * @return string
	 */
	public function renderformpageAction($formDefinition, $currentPageIndex) {
		$formFactory = new \TYPO3\Form\Factory\ArrayFormFactory();
		// TODO make preset name changable
		$formDefinition = $formFactory->build($formDefinition, 'default');
		$formDefinition->setRenderingOption('previewMode', TRUE);
		$form = $formDefinition->bind($this->request);
		$form->overrideCurrentPage($currentPageIndex);
		return $form->render();
	}
}
?>