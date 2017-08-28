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

use Neos\Flow\Annotations as Flow;
use Neos\Flow\Mvc\Controller\ActionController;

/**
 * Standard controller for the Neos.Form.YamlBuilder package
 *
 * @Flow\Scope("singleton")
 */
class StandardController extends ActionController
{
    /**
     * Standard controller
     */
    public function indexAction()
    {
        $this->redirect('index', 'FormManager');
    }
}
