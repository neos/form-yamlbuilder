<?php
namespace Neos\FormBuilder\Controller;

/*                                                                        *
 * This script belongs to the TYPO3 Flow package "Neos.FormBuilder".      *
 *                                                                        *
 * It is free software; you can redistribute it and/or modify it under    *
 * the terms of the GNU Lesser General Public License, either version 3   *
 *  of the License, or (at your option) any later version.                *
 *                                                                        *
 * The TYPO3 project - inspiring people to share!                         *
 *                                                                        */

use Neos\Flow\Mvc\Controller\ActionController;
use Neos\Form\Factory\ArrayFormFactory;
use Neos\Flow\Annotations as Flow;

/**
 * Standard controller for the Neos.FormBuilder package
 *
 * @Flow\Scope("singleton")
 */
class EditorController extends ActionController
{
    /**
     * @Flow\Inject
     * @var \Neos\Form\Persistence\FormPersistenceManagerInterface
     */
    protected $formPersistenceManager;

    /**
     * Displays the example form
     *
     * @param string $formPersistenceIdentifier
     * @param string $presetName
     * @return void
     */
    public function indexAction($formPersistenceIdentifier, $presetName = null)
    {
        if ($presetName === null) {
            $presetName = $this->settings['defaultPreset'];
        }
        $handlebarsTemplates = [];
        foreach ($this->settings['handlebarsTemplates'] as $templateName => $filePath) {
            $handlebarsTemplates[] = '<script type="text/x-handlebars" data-template-name="' . $templateName . '">' . file_get_contents($filePath) . '</script>';
        }

        $this->view->assign('handlebarsTemplates', implode("\n", $handlebarsTemplates));

        $this->view->assign('stylesheets', $this->filterAndSortArray($this->settings['stylesheets']));
        $this->view->assign('javaScripts', $this->filterAndSortArray($this->settings['javaScripts']));

        $this->view->assign('presetName', $presetName);
    }

    protected function filterAndSortArray($input)
    {
        $input = array_filter($input, function ($element) {
            return is_array($element) && isset($element['sorting']);
        });

        usort($input, function ($a, $b) {
            return $a['sorting'] - $b['sorting'];
        });
        return $input;
    }

    /**
     * @param string $formPersistenceIdentifier
     * @return array
     */
    public function loadformAction($formPersistenceIdentifier)
    {
        return json_encode($this->formPersistenceManager->load($formPersistenceIdentifier));
    }

    /**
     * @param string $formPersistenceIdentifier
     * @param array $formDefinition
     * @return string
     */
    public function saveformAction($formPersistenceIdentifier, array $formDefinition)
    {
        $this->formPersistenceManager->save($formPersistenceIdentifier, $formDefinition);

        return 'success';
    }

    /**
     * @param array $formDefinition
     * @param integer $currentPageIndex
     * @param string $presetName
     * @return string
     */
    public function renderformpageAction($formDefinition, $currentPageIndex, $presetName = null)
    {
        if ($presetName === null) {
            $presetName = $this->settings['defaultPreset'];
        }
        $formFactory = new ArrayFormFactory();
        $formDefinition = $formFactory->build($formDefinition, $presetName);
        $formDefinition->setRenderingOption('previewMode', true);
        $form = $formDefinition->bind($this->request, $this->response);
        $form->overrideCurrentPage($currentPageIndex);
        return $form->render();
    }
}
