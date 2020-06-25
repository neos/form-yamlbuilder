<?php
namespace Neos\Form\YamlBuilder\Controller;

/*
 * This file is part of the Neos.Form.YamlBuilder package.
 *
 * (c) Contributors of the Neos Project - www.neos.io
 *
 * This package is Open Source Software. For the full copyright and license
 * information, please view the LICENSE file which was distributed with this
 * source code.
 */

use Neos\Flow\Configuration\ConfigurationManager;
use Neos\Flow\Mvc\Controller\ActionController;
use Neos\Form\Factory\ArrayFormFactory;
use Neos\Flow\Annotations as Flow;
use Neos\Form\Persistence\FormPersistenceManagerInterface;

/**
 * Standard controller for the Neos.Form.YamlBuilder package
 *
 * @Flow\Scope("singleton")
 */
class EditorController extends ActionController
{
    /**
     * @Flow\Inject
     * @var FormPersistenceManagerInterface
     */
    protected $formPersistenceManager;

    /**
     * The settings of the Neos.Form package
     *
     * @var array
     * @api
     */
    protected $formSettings;

    /**
     * @Flow\Inject
     * @var ConfigurationManager
     * @internal
     */
    protected $configurationManager;

    /**
     * @internal
     */
    public function initializeObject()
    {
        $this->formSettings = $this->configurationManager->getConfiguration(ConfigurationManager::CONFIGURATION_TYPE_SETTINGS, 'Neos.Form');
    }
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

    /**
     * @param $input
     * @return array
     */
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
     * @return false|string
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
        $formIdentifier = $formDefinition['identifier'];

        $factoryClass = ArrayFormFactory::class;

        if (array_key_exists('formFactories', $this->formSettings['presets'][$presetName])
            && array_key_exists($formIdentifier, $this->formSettings['presets'][$presetName]['formFactories'])
        ) {
            $factoryClass = $this->formSettings['presets'][$presetName]['formFactories'][$formIdentifier];
        }

        $formFactory = $this->objectManager->get($factoryClass);
        $formDefinition = $formFactory->build($formDefinition, $presetName);
        $formDefinition->setRenderingOption('previewMode', true);
        $form = $formDefinition->bind($this->request, $this->response);
        $form->overrideCurrentPage($currentPageIndex);
        return $form->render();
    }
}
