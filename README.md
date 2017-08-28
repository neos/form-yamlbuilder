# Neos Form YAML Builder

This package implements a web-based IDE which can be used to create and edit YAML definitions of the **Neos.Form** package.

What you are reading now is the entry point of the API documentation. For a general introduction and usage examples, we suggest the documentation included in the Neos.Form package.

*To see the documentation for the specific classes, use the **jump to** menu in the top-right corner of this screen.*


## Sponsoring

This work has been generously sponsored by [AKOM360 - Multi Channel Marketing](	http://akom360.de)

It has been implemented by:

* Sebastian Kurfürst, [sandstorm|media](http://sandstorm-media.de) (architecture, implementation)
* Bastian Waidelich, [wwwision](http://wwwision.de) (styling)

## License

We license the form builder under the terms of the GNU Lesser General Public License (LGPL) version 2.1 or later versions.

## Extension Points

The Form Builder is meant to be extensible, on the following points:

- you can adjust the CSS styling
- you can override Handlebars templates to adjust the HTML markup of the form builder
- you can write **new editors** which are displayed in the *editor panel*, by
  subclassing `Neos.Form.YamlBuilder.View.Editor.AbstractPropertyEditor`
- you can write **new validator editors** which are displayed underneath the *validators* in the editor panel,
  by subclassing `Neos.Form.YamlBuilder.View.Editor.ValidatorEditor.DefaultValidatorEditor`
- you can write **new finisher editors** which are displayed underneath the *finishers*, in a process
  similar to creating new validator editors.

**If you want to extend the form builder, EmberJS and JavaScript knowledge is required.**

### Adjusting CSS styling and loading additional JavaScript files

The CSS files which are included in the form builder UI, and the JavaScript files being used,
are configured using `Settings.yaml` at path `Neos.Form.YamlBuilder.stylesheets` and `Neos.Form.YamlBuilder.javaScripts`.

They both have the same structure, that's why we'll only focus on explaining the CSS styling configuration
which looks as follows:

	Neos:
	  Form
	    YamlBuilder:
	      stylesheets:
	        slickGrid:
	          sorting: 10
	          files: ['resource://Neos.Form.YamlBuilder/Public/Library/SlickGrid/slick.grid.wrapped.css']
	        # … some more definitions here …
	        application:
	          sorting: 100
	          files: ['resource://Neos.Form.YamlBuilder/Public/Css/FormBuilder.css']

Underneath `Neos.Form.YamlBuilder.stylesheets` resides a list of "bundles" which need to be included. For each
bundle, the `files` array points to resources which should be included appropriately. The `sorting` determines the inclusion order (low numbers are included first).

You could even disable the inclusion of a particular style sheet, by setting it to NULL:

	Neos:
	  Form:
	    YamlBuilder:
	      stylesheets:
	        slickGrid: NULL

Inclusion and modification of the **JavaScript files** can be done in exactly the same manner.

## Overriding Handlebars Templates

You should first understand the Handlebars templates as they are used by EmberJS -- [read in their documentation if necessary](http://emberjs.com/#handlebars).

Each handlebars template which is used by the Form Builder is registered in the Settings.yaml:

	Neos:
	  Form:
	    YamlBuilder:
	      handlebarsTemplates:
	        ValidatorEditor: resource://Neos.Form.YamlBuilder/Private/Templates/FormBuilder/ValidatorEditor.html
	        # here follow lots of other handlebars templates

Underneath the `handlebarsTemplates`, an associative array is stored where the *key* is the **templateName** as being used in `Ember.View`, and the *value* is the filesystem location where the template is stored.

You can easily copy such a template to another package, and update the corresponding Setting. This way, you can arbitrarily adjust the Form Builder.

When the form builder is loaded, the handlebars templates are directly inserted into the HTML markup, as this is the preferred way of dealing with handlebars templates from within EmberJS.

### Implementing Custom Editors

In order to implement custom editors, you need to do the following:

- create a new JavaScript file and load it using the JavaScript loading mechanism explained above
- (probably) create a new Handlebars template and register it in the settings as explained above
- implement your editor; you can always have a look at the [existing editors](Resources/Private/CoffeeScript/view/editors/basic.html).

## Internals - Development and Compilation Process

If you want to develop the core of the Form Builder, then you need to know the things outlined in the following section.

### CoffeeScript, SASS, API Documentation

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
- `wrapCssFile`: You need to call this after upgrading the external JavaScript libraries.
  It wraps their CSS files with the selectors for the specific page parts where they are used.

### Unit Tests

The Form Builder has JavaScript unit tests for the model, which can be run by opening
`Tests/JavaScript/SpecRunner.html` in your browser.

### Names and Conventions

The YAML FormBuilder is structured as follows, and the following
names are used for it:

	+------------------------------------------------------------+
	|                                                            |
	|   Header                                                   |
	+-------------------+----------------------+-----------------+
	|                   |                      |                 |
	|                   |                      |                 |
	|                   |                      |                 |
	|      Structure    |                      |                 |
	|      Panel        |                      |                 |
	|                   |                      |                 |
	|                   |                      |                 |
	+-------------------+      Stage           |  Element Options|
	|                   |                      |  Panel          |
	|                   |                      |                 |
	|                   |                      |                 |
	|      Insert       |                      |                 |
	|      Element      |                      |                 |
	|      Panel        |                      |                 |
	|                   |                      |                 |
	|                   |                      |                 |
	|                   |                      |                 |
	+-------------------+----------------------+-----------------+


