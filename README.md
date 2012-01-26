#Form Builder#

Copyright 2012 Sebastian Kurfürst, Sandstorm Media UG (haftungsbeschränkt)

##Extension Points##

The Form Builder is meant to be extensible on the JavaScript side, mostly on two points:

- you can write new editors which are displayed in the *editor panel*, by
  subclassing `TYPO3.FormBuilder.View.Editor.AbstractPropertyEditor`
- you can write new validator editors which are displayed underneath the *validators* in the editor panel,
  by subclassing `TYPO3.FormBuilder.View.Editor.ValidatorEditor.DefaultValidatorEditor`

TODO: Document overriding TEMPLATES

##Development and Compilation Process##

###CoffeeScript, Sass, API Documentation###

This project uses CoffeeScript as JavaScript preprocessor, and SASS as CSS preprocessor.
Furthermore, it uses the docco-husky project for rendering documentation.

Installation:

- install Node.JS
- install a working ruby environment
- `gem install sass compass`
- `npm install -g coffee-script docco-husky`

Then, you can run `cake` in the top-level directory of the package, and will get a list
of build targets you can execute. The following targets exist:

- `build`: compile CoffeeScript and SASS to JavaScript and CSS, respectively
- `buildDocumentation`: Build the API documentation using docco-husky
- `wrapCssFile`: You need to call this after upgrading the external `SlickGrid` or `DynaTree` libraries.
  It wraps their CSS files with the selectors for the specific page parts where they are used.

###Unit Tests###

The Form Builder has JavaScript unit tests for the model, which can be run by opening
`Tests/JavaScript/SpecRunner.html` in your browser.

##License##

TODO INSERT