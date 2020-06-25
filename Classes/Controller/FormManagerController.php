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
use Neos\Flow\Exception;
use Neos\Flow\Mvc\Controller\ActionController;
use Neos\Flow\Mvc\Exception\StopActionException;
use Neos\Form\Factory\ArrayFormFactory;
use Neos\Form\Persistence\FormPersistenceManagerInterface;
use Symfony\Component\Yaml\Yaml;
use Neos\Flow\Annotations as Flow;

/**
 * Form Manager controller for the Neos.Form.YamlBuilder package
 *
 * @Flow\Scope("singleton")
 */
class FormManagerController extends ActionController
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
     * Displays the Form Manager in all its glory
     *
     * @return void
     */
    public function indexAction()
    {
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
    public function showAction($formPersistenceIdentifier, $presetName = null)
    {
        if ($presetName === null) {
            $presetName = $this->settings['defaultPreset'];
        }

        $formFactoryClass = ArrayFormFactory::class;

        if (array_key_exists('formFactories', $this->formSettings['presets'][$presetName])
            && array_key_exists($formPersistenceIdentifier, $this->formSettings['presets'][$presetName]['formFactories'])
        ) {
            $formFactoryClass = $this->formSettings['presets'][$presetName]['formFactories'][$formPersistenceIdentifier];
        }

        $this->view->assign('formPersistenceIdentifier', $formPersistenceIdentifier);
        $this->view->assign('presetName', $presetName);
        $this->view->assign('formFactoryClass', $formFactoryClass);
        $availablePresets = [];

        foreach ($this->formSettings['presets'] as $fromPresetName => $presetConfiguration) {
            $availablePresets[$fromPresetName] = isset($presetConfiguration['title']) ? $presetConfiguration['title'] : sprintf('[%s]', $fromPresetName);
        }
        $this->view->assign('availablePresets', $availablePresets);
    }

    /**
     * Creates a new Form and redirects to the Form Editor
     *
     * @param string $formName
     * @param string $templatePath
     * @return void
     * @throws Exception
     * @throws StopActionException
     */
    public function createAction($formName, $templatePath)
    {
        if (!isset($this->settings['newFormTemplates'][$templatePath])) {
            throw new Exception(sprintf('The template path "%s" is not allowed', $templatePath), 1329233410);
        }
        $form = Yaml::parse(file_get_contents($templatePath));
        $form['label'] = $formName;
        $formIdentifier = $this->convertFormNameToIdentifier($formName);
        $form['identifier'] = $formIdentifier;

        $formPersistenceIdentifier = $this->findUniquePersistenceIdentifier($formIdentifier);
        $this->formPersistenceManager->save($formPersistenceIdentifier, $form);

        $this->redirect('index', 'Editor', null, ['formPersistenceIdentifier' => $formPersistenceIdentifier]);
    }

    /**
     * Duplicates a given Form and redirects to the Form Editor
     *
     * @param string $formName
     * @param string $formPersistenceIdentifier persistence identifier of the form to duplicate
     * @return void
     * @throws Exception
     * @throws StopActionException
     */
    public function duplicateAction($formName, $formPersistenceIdentifier)
    {
        $formToDuplicate = $this->formPersistenceManager->load($formPersistenceIdentifier);
        $formToDuplicate['label'] = $formName;
        $formToDuplicate['identifier'] = $this->convertFormNameToIdentifier($formName);

        $formPersistenceIdentifier = $this->findUniquePersistenceIdentifier($formToDuplicate['identifier']);
        $this->formPersistenceManager->save($formPersistenceIdentifier, $formToDuplicate);

        $this->redirect('index', 'Editor', null, ['formPersistenceIdentifier' => $formPersistenceIdentifier]);
    }

    /**
     * @param string $formName
     * @return string the form identifier which is the lowerCamelCased form name
     */
    protected function convertFormNameToIdentifier($formName)
    {
        $formIdentifier = preg_replace('/[^a-zA-Z0-9-_]/', '', $formName);
        $formIdentifier = lcfirst($formIdentifier);
        return $formIdentifier;
    }

    /**
     * This takes a form identifier and returns a unique persistence identifier for it.
     * By default this is just similar to the identifier. But if a form with the same persistence identifier already
     * exists a suffix is appended until the persistence identifier is unique.
     *
     * @param string $formIdentifier lowerCamelCased form identifier
     * @return string unique form persistence identifier
     * @throws Exception
     */
    protected function findUniquePersistenceIdentifier($formIdentifier)
    {
        if (!$this->formPersistenceManager->exists($formIdentifier)) {
            return $formIdentifier;
        }
        for ($attempts = 1; $attempts < 100; $attempts ++) {
            $formPersistenceIdentifier = sprintf('%s_%d', $formIdentifier, $attempts);
            if (!$this->formPersistenceManager->exists($formPersistenceIdentifier)) {
                return $formPersistenceIdentifier;
            }
        }
        throw new Exception(sprintf('Could not find a unique persistence identifier for form identifier "%s" after %d attempts', $formIdentifier, $attempts), 1329842768);
    }
}
