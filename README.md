# Neos Form YAML Builder

This package implements a web-based IDE which can be used to create and edit YAML definitions of the **Neos.Form** package.

What you are reading now is the entry point of the API documentation. For a general introduction and usage examples, we suggest the documentation included in the Neos.Form package.

## Related Packages

Make sure to have a look at the other Flow Form Framework [Related Packages](https://github.com/neos/form/#related-packages)

## Sponsoring

This work has been generously sponsored by [AKOM360 - Multi Channel Marketing](	http://akom360.de)

It has been implemented by:

* Sebastian Kurfürst, [sandstorm|media](http://sandstorm-media.de) (architecture, implementation)
* Bastian Waidelich, [wwwision](http://wwwision.de) (styling)

## License

We license the Form YAML Builder under the terms of the GNU Lesser General Public License (LGPL) version 2.1 or later versions.

## Extension Points

The Form YAML Builder is meant to be extensible, on the following points:

- you can adjust the CSS styling
- you can override Handlebars templates to adjust the HTML markup of the form builder
- you can write **new editors** which are displayed in the *editor panel*, by
  subclassing `Neos.Form.YamlBuilder.View.Editor.AbstractPropertyEditor`
- you can write **new validator editors** which are displayed underneath the *validators* in the editor panel,
  by subclassing `Neos.Form.YamlBuilder.View.Editor.ValidatorEditor.DefaultValidatorEditor`
- you can write **new finisher editors** which are displayed underneath the *finishers*, in a process
  similar to creating new validator editors.
- you can configure your custom form factories for every preset individually

**If you want to extend the form builder, EmberJS and JavaScript knowledge is required.**

### Adjusting CSS styling and loading additional JavaScript files

The CSS files which are included in the form builder UI, and the JavaScript files being used,
are configured using `Settings.yaml` at path `Neos.Form.YamlBuilder.stylesheets` and `Neos.Form.YamlBuilder.javaScripts`.

They both have the same structure, that's why we'll only focus on explaining the CSS styling configuration
which looks as follows:

```yaml
Neos:
  Form:
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

Underneath `Neos.Form.YamlBuilder.stylesheets` resides a list of "bundles" which need to be included. For each
bundle, the `files` array points to resources which should be included appropriately. The `sorting` determines the inclusion order (low numbers are included first).

You could even disable the inclusion of a particular style sheet, by setting it to NULL:

```yaml
Neos:
  Form:
    YamlBuilder:
      stylesheets:
        slickGrid: ~
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
        ValidatorEditor: 'resource://Neos.Form.YamlBuilder/Private/Templates/FormBuilder/ValidatorEditor.html'
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

### Frontend Dev/Build Environment with Docker

Because we need NPM, Gem and CoffeeScript in specific versions, we have changed
the frontend build process to be encapsulated in Docker.

Everything outlined below is still correct; but it runs in a docker environment.

Installation:

- ensure you have Docker installed
- run `make build`

### CoffeeScript, SASS, API Documentation

This project uses CoffeeScript as JavaScript preprocessor, and SASS as CSS preprocessor.
Furthermore, it uses the docco-husky project for rendering documentation.

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

The Form YAML Builder is structured as follows, and the following
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
        options: ~
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

## Extending Form Builder

After working through this guide, you will have learned:

* How to include custom CSS into the form builder
* How to write a custom finisher editor

* **How can the form builder be adjusted**

An in-depth reference on how to extend the form builder using custom JavaScript can be found in the start page of the Form Builder
API documentation.

### Adjusting the Form Builder with Custom CSS

Let's say you want to adjust the form builder with a custom CSS file inside ``Your.Package/Resources/Public/FormBuilderAdjustments.css``. Then, you need to tell the form builder to load this additional stylesheet as well. You can do that using an entry inside ``Settings.yaml`` of your package which looks as follows:

```yaml
Neos:
  Form:
    YamlBuilder:
      stylesheets:
        customAdjustments:
          files: ['resource://Your.Package/Public/FormBuilderAdjustments.css']
          sorting: 200
```

Most important is the ``sorting`` property, as it defines the *order in which the CSS files are included*. Every sorting up to 100 is reserved for internal use by the form builder, so you should use sorting numbers above 100 unless you have a good reason to do otherwise.

> **Tip:** Loading additional JavaScript files into the form builder works in the same manner.

### Overriding Form Builder Handlebars Template

Let's say we want to adjust the header of the form builder, such that it displays your company up there as well. For that, we need to modify the default *handlebars template* for the header area.

> **Warning:** If you modify handlebars templates, you might need to adjust them after a new version of the form builder
   has been released! Modification of handlebars templates is useful for **unplanned extensibility**, but you should only
   do it as last resort!

The default template is located inside ``Neos.Form.YamlBuilder/Resources/Private/FormBuilderTemplates/Header.html`` and looks as follows:

```html
<h1>Form Builder - {{Neos.Form.YamlBuilder.Model.Form.formDefinition.label}}</h1>
{{#if Neos.Form.YamlBuilder.Model.Form.currentlyLoadingPreview}}
   <span id="neos-form-yamlbuilder-loading">Loading..</span>
{{/if}}

<ul id="neos-form-yamlbuilder-toolbar">
   <li class="neos-form-yamlbuilder-preset">
      {{view Neos.Form.YamlBuilder.View.Header.PresetSelector}}
   </li>
   <li class="neos-form-yamlbuilder-preview">
      {{#view Neos.Form.YamlBuilder.View.Header.PreviewButton class="neos-form-yamlbuilder-button icon"}}Preview{{/view}}
   </li>
   <li class="neos-form-yamlbuilder-save">
    {{#view Neos.Form.YamlBuilder.View.Header.SaveButton class="neos-form-yamlbuilder-button icon"}}Save{{/view}}
   </li>
</ul>
```

We can just copy it to ``Your.Package/Resources/Private/FormBuilderTemplates/Header.html`` and adjust it as needed, modifying the part inside the ``<h1>...</h1>`` to:

```html
<h1>Your Company Form Builder - {{Neos.Form.YamlBuilder.Model.Form.formDefinition.label}}</h1>
```

Then, we need to tell the form builder that we want to use a different handlebars template for the header. For that, we need the following ``Settings.yaml``:

```yaml
Neos:
  Form:
    YamlBuilder:
      handlebarsTemplates:
        Header: 'resource://Your.Package/Private/FormBuilderTemplates/Header.html'
```

> **Warning:** Make sure that your package is loaded **after the Neos.Form.YamlBuilder package** if you want to override such settings.

### Creating a Custom Editor

Every form element is edited on the right side of the Form YAML Builder in the *element options panel*. In order to be flexible and extensible, the element options panel is a container for **editors** which, as a whole, edit the form element. There are a multitude of predefined editors, ranging from a simple text input field up to a grid widget for editing properties.

All editors for a given form element are defined inside the ``formElementTypes`` definition, looking as follows:

```yaml
# we are now inside Neos:Form:presets:[presetName]:formElementTypes
'Neos.Form:TextMixin':
  formBuilder:
    editors:
      placeholder: # an arbitrary key for identifying the editor instance
        sorting: 200 # the sorting determines the ordering of the different editors inside the element options panel
        viewName: 'JavaScript.View.Class.Name' # the JavaScript view class name which should be used here
        # additionally, you can define view-specific options here
        # here, you can define some more editors.
```

We will now create a custom editor for rendering a *select* box, and will add it to the *File Upload* form element such that a user can choose the file types he allows. The finished editor is part of the standard YamlBuilder distribution inside ``Neos.Form.YamlBuilder/Resources/Private/CoffeeScript/elementOptionsPanelEditors/basic.coffee``.

> **Note:** If you want to create your completely own editor, you need to include the additional JavaScript file. How this is done is explained in detail above

#### The Basic Setup

> **Note:** We'll develop the editor in `CoffeeScript <http://coffeescript.org>`_, but you are of course free to also use JavaScript.

We will extend our editor from ``Neos.Form.YamlBuilder.View.ElementOptionsPanel.Editor.AbstractPropertyEditor``:

```coffeescript
Neos.Form.YamlBuilder.View.ElementOptionsPanel.Editor.SelectEditor = AbstractPropertyEditor.extend {
   templateName: 'ElementOptionsPanel-SelectEditor'
}
```

Then, we will create a basic handlebars template and register it underneath ``ElementOptionsPanel-SelectEditor`` (as described above). We'll just copy over an existing editor template and slightly adjust it:

```html
<div class="neos-form-yamlbuilder-controlGroup">
   <label>{{label}}:</label>
   <div class="neos-form-yamlbuilder-controls">
      [select should come here]
   </div>
</div>
```

> **Note:** Don't forget to register the handlebars template ``ElementOptionsPanel-SelectEditor`` inside your ``Settings.yaml``.

Now that we have all the pieces ready, let's actually use the editor inside the ``Neos.Form:FileUpload`` form element:

```yaml
# we are now inside Neos:Form:presets:[presetName]:formElementTypes
'Neos.Form:FileUpload':
  formBuilder:
    editors:
      allowedExtensions:
        sorting: 200
        viewName: 'Neos.Form.YamlBuilder.View.ElementOptionsPanel.Editor.SelectEditor'
```

After reloading the form builder, you will see that the file upload field has a field: ``[select should come here]`` displayed inside the element options panel.

Now that we have the basics set up, let's fill the editor with life by actually implementing it.

#### Implementing the Editor

Everything inside here is just JavaScript development with EmberJS, using bindings and computed properties. If that sound like chinese to you, head over to the `EmberJS <http://emberjs.com>`_ website and read it up.

We somehow need to configure the available options inside the editor, and come up with the following YAML on how we want to configure the file types:

```yaml
allowedExtensions:
  sorting: 200
  label: 'Allowed File Types'
  propertyPath: 'properties.allowedExtensions'
  viewName: 'Neos.Form.YamlBuilder.View.ElementOptionsPanel.Editor.SelectEditor'
  availableElements:
    0:
      value: ['doc', 'docx', 'odt', 'pdf']
      label: 'Documents (doc, docx, odt, pdf)'
    1:
      value: ['xls']
      label: 'Spreadsheet documents (xls)'
```

Furthermore, the above example sets the ``label`` and ``propertyPath`` options of the element editor. The ``label`` is shown in front of the element, and the ``propertyPath`` points to the form element option which shall be modified using this editor.

All properties of such an editor definition are made available inside the editor object itself, i.e. the ``SelectEditor`` now magically has an ``availableElements`` property which we can use inside the Handlebars template to bind the select box options to. Thus, we remove the ``[select should come here]`` and replace it with ``Ember.Select``:

```html
{{view Ember.Select contentBinding="availableElements" optionLabelPath="content.label"}}
```

Now, if we reload, we already see the list of choices being available as a dropdown.

#### Saving the Selection

Now, we only need to save the selection inside the model again. For that, we bind the current selection to a property in our view using the ``selectionBinding`` of the ``Ember.Select`` view:

```html
{{view Ember.Select contentBinding="availableElements" optionLabelPath="content.label" selectionBinding="selectedValue"}}
```

Then, let's create a *computed property* ``selectedValue`` inside the editor implementation, which updates the ``value`` property and triggers the change notification callback ``@valueChanged()``:

```coffeescript
SelectEditor = AbstractPropertyEditor.extend {
   templateName: 'ElementOptionsPanel-SelectEditor'
   # API: list of available elements to be shown in the select box; each element should have a "label" and a "value".
   availableElements: null

   selectedValue: ((k, v) ->
      if arguments.length >= 2
         # we need to set the value
         @set('value', v.value)
         @valueChanged()

      # get the current value
      for element in @get('availableElements')
         return element if element.value == @get('value')

      # fallback if value not found
      return null
   ).property('availableElements', 'value').cacheable()
}
```

That's it :)

### Creating a Finisher Editor

Let's say we have implemented an *DatabaseFinisher* which has some configuration options like the table name, and you want to make these configuration options editable inside the Form Builder. This can be done using a custom handlebars template, and some configuration. In many cases, you do not need to write any JavaScript for that.

You need to do three things:

1. Register the finisher as a *Finisher Preset*
2. Configure the finisher editor for the form to include the newly created finisher as available finisher
3. create and include the handlebars template

```yaml
Neos:
  Form:
    presets:
      yourPresetName: # fill in your preset name here, or "default"
        # 1. Register your finisher as finisher preset
        finisherPresets:
          'Your.Package:DatabaseFinisher':
             implementationClassName: 'Your\Package\Finishers\DatabaseFinisher'
        formElementTypes:
          'Neos.Form:Form':
            formBuilder:
              editors:
                finishers:
                  availableFinishers:
                    # Configure the finisher editor for the form to include
                    # the newly created finisher as available finisher
                    'Your.Package:DatabaseFinisher':
                      label: 'Database Persistence Finisher'
                      templateName: 'Finisher-YourPackage-DatabaseFinisher'
    YamlBuilder:
      handlebarsTemplates:
        # include the handlebars template
        Finisher-YourPackage-DatabaseFinisher: 'resource://Your.Package/Private/FormBuilderTemplates/DatabaseFinisher.html'
```

Now, you only need to include the appropriate Handlebars template, which could look as follows:

```html
<h4>
   {{label}}
   {{#view Ember.Button target="parentView" action="remove"
                        isVisibleBinding="notRequired"
                        class="neos-form-yamlbuilder-removeButton"}}Remove{{/view}}
</h4>

<div class="neos-form-yamlbuilder-controlGroup">
   <label>Database Table</label>
   <div class="neos-form-yamlbuilder-controls">
      {{view Ember.TextField valueBinding="currentCollectionElement.options.databaseTable"}}
   </div>
</div>
```

> **Tip:** Creating a custom *validator editor* works in the same way, just that they have to be registered
   underneath ``validatorPresets`` and the editor is called ``validators`` instead of ``finishers``.

### Configuring a custom form factory

If needed, you can implement your custom form factories und configure them to be used for diffrent presets indually.

```yaml
Neos:
  Form:
    YamlBuilder:
      presets:
        myPreset:
          formFactories:
            myFormPersitenceIdentifier: '\MyVendor\MyPackage\PathTo\MyFormFactory'
```

With this configurtion, your custom form factory will be used for generating your custom form when rendering the form for the preview or edit views of the form.
