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

use Neos\Flow\Annotations as Flow;
use Neos\Flow\Mvc\Controller\ActionController;

/**
 * Standard controller for the Neos.FormBuilder package
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
