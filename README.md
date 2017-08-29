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

```yaml
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
```
	  files: ['resource://Neos.Form.YamlBuilder/Public/Css/FormBuilder.css']

Underneath `Neos.Form.YamlBuilder.stylesheets` resides a list of "bundles" which need to be included. For each
bundle, the `files` array points to resources which should be included appropriately. The `sorting` determines the inclusion order (low numbers are included first).

You could even disable the inclusion of a particular style sheet, by setting it to NULL:

```yaml
Neos:
  Form:
    YamlBuilder:
      stylesheets:
	slickGrid: NULL
```

Inclusion and modification of the **JavaScript files** can be done in exactly the same manner.

## Overriding Handlebars Templates

You should first understand the Handlebars templates as they are used by EmberJS -- [read in their documentation if necessary](http://emberjs.com/#handlebars).

Each handlebars template which is used by the Form Builder is registered in the Settings.yaml:

```yaml
Neos:
  Form:
    YamlBuilder:
      handlebarsTemplates:
	ValidatorEditor: resource://Neos.Form.YamlBuilder/Private/Templates/FormBuilder/ValidatorEditor.html
	# here follow lots of other handlebars templates
```

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


## Configuring Form Builder

After this guide, you will have learned how to **Configure the Form Builder through settings**

### Adding a New Form Element Inside "Create Elements"

Let's say you have created your form element, and want to make it available inside the Form Builder. For that, you need some YAML configuration which looks as follows:

```yaml
# we are now inside Neos:Form:presets:[presetName]
formElementTypes:
  'Your.Package:YourFormElement':
    # the definitions for your form element
    formBuilder:
      label: 'Your New Form Element'
      group: custom
      sorting: 200
```

To determine whether a form element is visible in the Form Builder, you must set ``formBuilder:group`` to a valid group. A *form element group* is used to visually group the available form elements together. In the default profile, the following groups are configured:

* input
* select
* custom
* container

The ``label`` is -- as you might expect -- the human-readable label, while the ``sorting`` determines the ordering of form elements inside their form element group.

### Creating a New Form Element Group

All form element groups are defined inside ``formElementGroups`` inside the preset, so that's how you can add a new group:

```yaml
# we are now inside Neos:Form:presets:[presetName]
formElementGroups:
  specialCustom:
    sorting: 500
    label: 'My special custom group'
```

For each group, you need to specify a human-readable ``label``, and the ``sorting`` (which determines the ordering of the groups).

### Setting Default Values for Form Elements

When a form element is created, you can define some default values which are directly set on the form element. As an example, let's imagine you want to build a ``ProgrammingLanguageSelect`` where the user can choose his favorite programming language.

In this case, we want to define some default programming languages, but the integrator who builds the form should be able to add custom options as well. These default options can be set in ``Settings.yaml`` using the ``formBuilder:predefinedDefaults`` key.

Here follows the full configuration for the ``ProgrammingLanguageSelect`` (which is an example taken from the ``Neos.FormExample`` package):

```yaml
# we are now inside Neos:Form:presets:[presetName]
formElementTypes:
  'Neos.FormExample:ProgrammingLanguageSelect':
    superTypes:
      'Neos.Form:SingleSelectRadiobuttons': TRUE
    renderingOptions:
      templatePathPattern: 'resource://Neos.Form/Private/Form/SingleSelectRadiobuttons.html'

      # here follow the form builder specific options
      formBuilder:
	group: custom
	label: 'Programming Language Select'

	# we now set some defaults which are applied once the form element is inserted to the form
	predefinedDefaults:
	  properties:
	    options:
	      0:
		_key: 'php'
		_value: 'PHP'
	      1:
		_key: 'java'
		_value: 'Java etc'
	      2:
		_key: 'js'
		_value: 'JavaScript'
```

#### Contrasting Use Case: Gender Selection

Inside *Creating a new form element*, we have implemented a special *Gender Select*. Let's think a second about the differences between the *Gender Select* and the *Programming Language Select* examples:

For a *Gender* select field, the integrator using the form builder does not need to set any options for this form element, as the available choices (``Female`` and ``Male``) are predefined inside the *form element template*.

In the case of the *programming language select*, we only want to set some sensible defaults for the integrator, but want him to be able to adjust the values.

Choosing which strategy to use depends mostly on the expected usage patterns:

* In the *gender select* example, if a **new option is added to the list afterwards**, this will directly be reflected in *all forms* which use this input field.
* If you use ``predefinedDefaults``, changing these will be only applied to **new elements**, but not to already existing elements.

> **Note:** In order to make the gender selection work nicely with the Form Builder, we should disable the ``options`` editor as follows (as the options should not be editable by the implementor):

```yaml
# we are now inside Neos:Form:presets:[presetName]
formElementTypes:
  'Neos.FormExample:GenderSelect':
    formBuilder:
      editors:
	# Disable "options" editor
	options: null
```

> **Tip:** The same distinction between using ``formBuilder:predefinedDefaults`` and the form element type definition directly can also be used to add other elements like ``Validators`` or ``Finishers``.


### Marking Validators and Finishers As Required

Sometimes, you want to simplify the Form Builder User Interface and make certain options easier for your users. A frequent use-case is that you want that a certain validator, like the ``StringLength`` validator, is always shown in the user interface as it is very often used.

This can be configured as follows:

```yaml
# we are now inside Neos:Form:presets:[presetName]
formElementTypes:
  'Neos.Form:TextMixin': # or any other type here
    formBuilder:
      editors:
	validation:
	  availableValidators:
	    'Neos.Flow:StringLength': # or any other validator
	      # mark this validator required such that it is always shown.
	      required: true
```

#### Finishers

The same works for Finishers, for example the following configuration makes the EmailFinisher mandatory:

```yaml
# we are now inside Neos:Form:presets:[presetName]
formElementTypes:
  'Neos.Form:Form':
    formBuilder:
      editors:
	finishers:
	  availableFinishers:
	    'Neos.Form:Email': # or any other finisher
	      # mark this finisher required such that it is always shown.
	      required: true
```


### Finishing Up

You should now have some receipes at hand on how to modify the Form Builder. Read the next chapter for some more advanced help.
