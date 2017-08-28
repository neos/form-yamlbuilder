<?php
namespace Neos\Form\YamlBuilder\ViewHelpers;

/*
 * This file is part of the Neos.Form.YamlBuilder package.
 *
 * (c) Contributors of the Neos Project - www.neos.io
 *
 * This package is Open Source Software. For the full copyright and license
 * information, please view the LICENSE file which was distributed with this
 * source code.
 */

use Neos\Flow\Annotations as Flow;
use Neos\FluidAdaptor\Core\ViewHelper\AbstractViewHelper;
use Neos\FluidAdaptor\Core\ViewHelper\Exception;
use Neos\Form\Utility\SupertypeResolver;

/**
 * @todo rename
 */
class JsonConfigurationViewHelper extends AbstractViewHelper
{
    /**
     * @var boolean
     */
    protected $escapeOutput = false;

    /**
     * @Flow\Inject
     * @var \Neos\Flow\ResourceManagement\ResourceManager
     */
    protected $resourceManager;

    /**
     * @Flow\Inject
     * @var \Neos\Form\Factory\ArrayFormFactory
     */
    protected $formBuilderFactory;

    /**
     * @Flow\Inject
     * @var \Neos\Flow\Security\Context
     */
    protected $securityContext;

    /**
     * @param string $presetName
     * @return string
     */
    public function render($presetName = 'default')
    {
        $mergedConfiguration = [];

        $presetConfiguration = $this->formBuilderFactory->getPresetConfiguration($presetName);
        $supertypeResolver = new SupertypeResolver($presetConfiguration['formElementTypes']);
        $mergedConfiguration['formElementTypes'] = $supertypeResolver->getCompleteMergedTypeDefinition(true);

        $mergedConfiguration['formElementGroups'] = isset($presetConfiguration['formElementGroups']) ? $presetConfiguration['formElementGroups'] : [];

        $stylesheets = isset($presetConfiguration['stylesheets']) ? $presetConfiguration['stylesheets'] : [];
        $mergedConfiguration['stylesheets'] = [];
        foreach ($stylesheets as $stylesheet) {
            if (isset($stylesheet['skipInFormBuilder']) && $stylesheet['skipInFormBuilder'] === true) {
                continue;
            }
            $mergedConfiguration['stylesheets'][] = $this->resolveResourcePath($stylesheet['source']);
        }

        $javaScripts = isset($presetConfiguration['javaScripts']) ? $presetConfiguration['javaScripts'] : [];
        $mergedConfiguration['javaScripts'] = [];
        foreach ($javaScripts as $javaScript) {
            if (isset($javaScript['skipInFormBuilder']) && $javaScript['skipInFormBuilder'] === true) {
                continue;
            }
            $mergedConfiguration['javaScripts'][] = $this->resolveResourcePath($javaScript['source']);
        }

        $mergedConfiguration['endpoints']['formPageRenderer'] = $this->controllerContext->getUriBuilder()->uriFor('renderformpage');
        $mergedConfiguration['endpoints']['loadForm'] = $this->controllerContext->getUriBuilder()->uriFor('loadform');
        $mergedConfiguration['endpoints']['saveForm'] = $this->controllerContext->getUriBuilder()->uriFor('saveform');
        $mergedConfiguration['endpoints']['editForm'] = $this->controllerContext->getUriBuilder()->uriFor('index');
        $mergedConfiguration['endpoints']['previewForm'] = $this->controllerContext->getUriBuilder()->uriFor('show', [], 'FormManager');

        $mergedConfiguration['csrfToken'] = $this->securityContext->getCsrfProtectionToken();

        $mergedConfiguration['formPersistenceIdentifier'] = $this->controllerContext->getArguments()->getArgument('formPersistenceIdentifier')->getValue();

        $mergedConfiguration['presetName'] = $presetName;

        $availablePresets = [];
        foreach ($this->formBuilderFactory->getPresetNames() as $presetName) {
            $presetConfiguration = $this->formBuilderFactory->getPresetConfiguration($presetName);
            $availablePresets[] = [
                'name' => $presetName,
                'title' => (isset($presetConfiguration['title']) ? $presetConfiguration['title'] : $presetName)
            ];
        }
        $mergedConfiguration['availablePresets'] = $availablePresets;


        return json_encode($mergedConfiguration);
    }

    /**
     * @param string $resourcePath
     * @return string
     * @throws \Neos\FluidAdaptor\Core\ViewHelper\Exception
     */
    protected function resolveResourcePath($resourcePath)
    {
        // TODO: This method should be somewhere in the resource manager probably?
        $matches = [];
        preg_match('#resource://([^/]*)/Public/(.*)#', $resourcePath, $matches);
        if ($matches === []) {
            throw new Exception('Resource path "' . $resourcePath . '" can\'t be resolved.', 1328543327);
        }
        $package = $matches[1];
        $path = $matches[2];
        return $this->resourceManager->getPublicPackageResourceUri($package, 'Packages/' . $package . '/' . $path);
    }
}
