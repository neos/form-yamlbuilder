(function() {
  var TYPO3, convertToSimpleObject, javaScript, stylesheet, _i, _j, _len, _len2, _ref, _ref2, _ref3, _ref4, _ref5, _ref6,
    _this = this,
    __hasProp = Object.prototype.hasOwnProperty;

  TYPO3 = window.TYPO3 || {};

  window.TYPO3 = TYPO3;

  window.onbeforeunload = function(e) {
    var text;
    if (!TYPO3.FormBuilder.Model.Form.get('unsavedContent')) return;
    e = e || window.event;
    text = 'There is unsaved content. Are you sure that you want to close the browser?';
    if (e) e.returnValue = text;
    return text;
  };

  window.onerror = function(errorMessage, url, lineNumber) {
    alert("There was a JavaScript error in File " + url + ", line " + lineNumber + ": " + errorMessage + ". Please report the error to the developers");
    return false;
  };

  TYPO3.FormBuilder = Ember.Application.create({
    rootElement: 'body'
  });

  TYPO3.FormBuilder.Configuration = window.FORMBUILDER_CONFIGURATION;

  if ((_ref = TYPO3.FormBuilder.Configuration) != null ? _ref.stylesheets : void 0) {
    _ref2 = TYPO3.FormBuilder.Configuration.stylesheets;
    for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
      stylesheet = _ref2[_i];
      $('head').append($('<link rel="stylesheet" />').attr('href', stylesheet));
    }
  }

  if ((_ref3 = TYPO3.FormBuilder.Configuration) != null ? _ref3.javaScripts : void 0) {
    _ref4 = TYPO3.FormBuilder.Configuration.javaScripts;
    for (_j = 0, _len2 = _ref4.length; _j < _len2; _j++) {
      javaScript = _ref4[_j];
      $.getScript(javaScript);
    }
  }

  if ((_ref5 = TYPO3.FormBuilder.Configuration) != null ? _ref5.formPersistenceIdentifier : void 0) {
    $.getJSON(TYPO3.FormBuilder.Configuration.endpoints.loadForm, {
      formPersistenceIdentifier: (_ref6 = TYPO3.FormBuilder.Configuration) != null ? _ref6.formPersistenceIdentifier : void 0
    }, function(data, textStatus, jqXHR) {
      TYPO3.FormBuilder.Model.Form.set('formDefinition', TYPO3.FormBuilder.Model.Renderable.create(data));
      return TYPO3.FormBuilder.Model.Form.set('unsavedContent', false);
    });
  }

  TYPO3.FormBuilder.Validators = {};

  TYPO3.FormBuilder.Validators.isNumberOrBlank = function(n) {
    if (n === '' || n === null || n === void 0) return true;
    return !isNaN(parseFloat(n)) && isFinite(n);
  };

  TYPO3.FormBuilder.Utility = {};

  convertToSimpleObject = function(input) {
    var key, simpleObject, value;
    simpleObject = {};
    for (key in input) {
      if (!__hasProp.call(input, key)) continue;
      value = input[key];
      if (key.match(/^__/) || key === 'parentRenderable') continue;
      if (typeof value === 'function') {} else if (typeof value === 'object') {
        simpleObject[key] = convertToSimpleObject(value);
      } else {
        simpleObject[key] = value;
      }
    }
    return simpleObject;
  };

  TYPO3.FormBuilder.Utility.convertToSimpleObject = convertToSimpleObject;

  TYPO3.FormBuilder.Utility.getUri = function(baseUri, presetName) {
    var uri;
    if (presetName == null) {
      presetName = TYPO3.FormBuilder.Configuration.presetName;
    }
    uri = baseUri + ("?formPersistenceIdentifier=" + (encodeURIComponent(TYPO3.FormBuilder.Configuration.formPersistenceIdentifier)) + "&presetName=" + (encodeURIComponent(presetName)));
    return uri;
  };

  TYPO3.FormBuilder.Model = {};

  TYPO3.FormBuilder.Model.Form = Ember.Object.create({
    formDefinition: null,
    unsavedContent: false,
    currentlySelectedRenderable: null,
    saveStatus: '',
    save: function(callback) {
      var formDefinition, _ref7,
        _this = this;
      if (callback == null) callback = null;
      this.set('saveStatus', 'currently-saving');
      formDefinition = TYPO3.FormBuilder.Utility.convertToSimpleObject(this.get('formDefinition'));
      return $.post(TYPO3.FormBuilder.Configuration.endpoints.saveForm, {
        formPersistenceIdentifier: (_ref7 = TYPO3.FormBuilder.Configuration) != null ? _ref7.formPersistenceIdentifier : void 0,
        formDefinition: formDefinition
      }, function(data, textStatus, jqXHR) {
        if (data === 'success') {
          _this.set('saveStatus', 'saved');
          _this.set('unsavedContent', false);
          if (callback) return callback(true);
        } else {
          _this.set('saveStatus', 'save-error');
          if (callback) return callback(false);
        }
      });
    },
    onFormDefinitionChange: (function() {
      if (!this.get('formDefinition')) return;
      return this.set('currentlySelectedRenderable', this.get('formDefinition'));
    }).observes('formDefinition'),
    contentChanged: (function() {
      return this.set('unsavedContent', true);
    }).observes('formDefinition.__nestedPropertyChange')
  });

  TYPO3.FormBuilder.Model.Renderable = Ember.Object.extend({
    parentRenderable: null,
    renderables: null,
    __nestedPropertyChange: 0,
    type: null,
    typeDefinition: (function() {
      var formElementTypeName;
      formElementTypeName = this.get('type');
      if (!formElementTypeName) return null;
      return TYPO3.FormBuilder.Model.FormElementTypes.get(formElementTypeName);
    }).property('type').cacheable(),
    init: function() {
      this.renderables = [];
      return this.renderables.addArrayObserver(this);
    },
    setUnknownProperty: function(k, v) {
      this[k] = v;
      this.addObserver(k, this, 'somePropertyChanged');
      return this.somePropertyChanged(this, k);
    },
    setPathRecursively: function(path, v) {
      var currentObject, firstPartOfPath;
      currentObject = this;
      while (path.indexOf('.') > 0) {
        firstPartOfPath = path.slice(0, path.indexOf('.'));
        path = path.slice(firstPartOfPath.length + 1);
        if (!Ember.get(currentObject, firstPartOfPath)) {
          currentObject[firstPartOfPath] = {};
        }
        currentObject = Ember.get(currentObject, firstPartOfPath);
      }
      return currentObject[path] = v;
    },
    somePropertyChanged: function(theInstance, propertyName) {
      this.set('__nestedPropertyChange', this.get('__nestedPropertyChange') + 1);
      if (this.parentRenderable) {
        return this.parentRenderable.somePropertyChanged(this.parentRenderable, "renderables." + (this.parentRenderable.get('renderables').indexOf(this)) + "." + propertyName);
      }
    },
    arrayWillChange: function(subArray, startIndex, removeCount, addCount) {
      var i, _ref7, _results;
      _results = [];
      for (i = startIndex, _ref7 = startIndex + removeCount; startIndex <= _ref7 ? i < _ref7 : i > _ref7; startIndex <= _ref7 ? i++ : i--) {
        _results.push(subArray.objectAt(i).set('parentRenderable', null));
      }
      return _results;
    },
    arrayDidChange: function(subArray, startIndex, removeCount, addCount) {
      var i, _ref7;
      for (i = startIndex, _ref7 = startIndex + addCount; startIndex <= _ref7 ? i < _ref7 : i > _ref7; startIndex <= _ref7 ? i++ : i--) {
        subArray.objectAt(i).set('parentRenderable', this);
      }
      this.set('__nestedPropertyChange', this.get('__nestedPropertyChange') + 1);
      if (this.parentRenderable) {
        return this.parentRenderable.somePropertyChanged(this.parentRenderable, "renderables." + (this.parentRenderable.get('renderables').indexOf(this)) + ".renderables");
      }
    },
    _path: (function() {
      if (this.parentRenderable) {
        return "" + (this.parentRenderable.get('_path')) + ".renderables." + (this.parentRenderable.get('renderables').indexOf(this));
      } else {
        return '';
      }
    }).property(),
    findEnclosingPage: function() {
      var referenceRenderable;
      referenceRenderable = this;
      while (referenceRenderable.getPath('parentRenderable.parentRenderable') !== null) {
        referenceRenderable = referenceRenderable.get('parentRenderable');
      }
      return referenceRenderable;
    },
    findEnclosingCompositeRenderableWhichIsNotOnTopLevel: function() {
      var referenceRenderable;
      referenceRenderable = this;
      while (!referenceRenderable.getPath('typeDefinition.formBuilder._isCompositeRenderable')) {
        if (referenceRenderable.getPath('typeDefinition.formBuilder._isTopLevel')) {
          return null;
        }
        referenceRenderable = referenceRenderable.get('parentRenderable');
      }
      if (referenceRenderable.getPath('typeDefinition.formBuilder._isTopLevel')) {
        return null;
      }
      return referenceRenderable;
    },
    removeWithConfirmationDialog: function() {
      var thisRenderable;
      thisRenderable = this;
      return $('<div>Are you sure that you want to remove this Element?</div>').dialog({
        dialogClass: 'typo3-formbuilder-dialog',
        title: 'Remove Element?',
        modal: true,
        resizable: false,
        buttons: {
          'Delete': function() {
            thisRenderable.remove();
            return $(this).dialog('close');
          },
          'Cancel': function() {
            return $(this).dialog('close');
          }
        }
      });
    },
    remove: function(updateCurrentRenderable) {
      if (updateCurrentRenderable == null) updateCurrentRenderable = true;
      if (updateCurrentRenderable) {
        TYPO3.FormBuilder.Model.Form.set('currentlySelectedRenderable', this.get('parentRenderable'));
      }
      return this.getPath('parentRenderable.renderables').removeObject(this);
    }
  });

  TYPO3.FormBuilder.Model.Renderable.reopenClass({
    create: function(obj) {
      var childRenderable, childRenderables, k, renderable, v, _k, _len3;
      childRenderables = obj.renderables;
      delete obj.renderables;
      renderable = Ember.Object.create.call(TYPO3.FormBuilder.Model.Renderable, obj);
      for (k in obj) {
        v = obj[k];
        renderable.addObserver(k, renderable, 'somePropertyChanged');
      }
      if (childRenderables) {
        for (_k = 0, _len3 = childRenderables.length; _k < _len3; _k++) {
          childRenderable = childRenderables[_k];
          renderable.get('renderables').pushObject(TYPO3.FormBuilder.Model.Renderable.create(childRenderable));
        }
      }
      return renderable;
    }
  });

  TYPO3.FormBuilder.Model.FormElementType = Ember.Object.extend({
    type: null,
    __cssClassNames: (function() {
      return "typo3-formbuilder-group-" + (this.getPath('formBuilder.group')) + " typo3-formbuilder-type-" + (this.get('type').toLowerCase().replace(/[^a-z0-9]/g, '-'));
    }).property('formBuilder.group', 'type').cacheable()
  });

  TYPO3.FormBuilder.Model.FormElementTypes = Ember.Object.create({
    allTypeNames: [],
    init: function() {
      var typeConfiguration, typeName, _ref7, _ref8, _results;
      if (((_ref7 = TYPO3.FormBuilder.Configuration) != null ? _ref7.formElementTypes : void 0) == null) {
        return;
      }
      _ref8 = TYPO3.FormBuilder.Configuration.formElementTypes;
      _results = [];
      for (typeName in _ref8) {
        typeConfiguration = _ref8[typeName];
        typeConfiguration.type = typeName;
        this.allTypeNames.push(typeName);
        _results.push(this.set(typeName, TYPO3.FormBuilder.Model.FormElementType.create(typeConfiguration)));
      }
      return _results;
    }
  });

  TYPO3.FormBuilder.Model.FormElementGroups = Ember.Object.create({
    allGroupNames: [],
    init: function() {
      var groupConfiguration, groupName, _ref7, _ref8, _results;
      if (((_ref7 = TYPO3.FormBuilder.Configuration) != null ? _ref7.formElementGroups : void 0) == null) {
        return;
      }
      _ref8 = TYPO3.FormBuilder.Configuration.formElementGroups;
      _results = [];
      for (groupName in _ref8) {
        groupConfiguration = _ref8[groupName];
        this.allGroupNames.push(groupName);
        _results.push(this.set(groupName, Ember.Object.create(groupConfiguration)));
      }
      return _results;
    }
  });

  TYPO3.FormBuilder.View = {};

  TYPO3.FormBuilder.View.ContainerView = Ember.ContainerView.extend({
    instanciatedViews: null,
    onInstanciatedViewsChange: (function() {
      var view, _k, _len3, _ref7, _results;
      this.removeAllChildren();
      _ref7 = this.get('instanciatedViews');
      _results = [];
      for (_k = 0, _len3 = _ref7.length; _k < _len3; _k++) {
        view = _ref7[_k];
        _results.push(this.get('childViews').pushObject(view));
      }
      return _results;
    }).observes('instanciatedViews')
  });

  TYPO3.FormBuilder.View.Select = Ember.Select.extend({
    attributeBindings: ['disabled']
  });

  TYPO3.FormBuilder.View.TextField = Ember.TextField.extend({
    validatorName: null,
    _lastValidValue: false,
    validate: function(v) {
      var validator;
      if (this.get('validatorName')) {
        validator = Ember.getPath(this.get('validatorName'));
        return validator.call(this, v);
      }
      return true;
    },
    validatedValue: (function(k, v) {
      if (arguments.length >= 2) {
        if (this.validate(v)) this._lastValidValue = v;
        return this._lastValidValue;
      } else {
        return this._lastValidValue;
      }
    }).property().cacheable(),
    valueBinding: 'validatedValue'
  });

  TYPO3.FormBuilder.View.Application = Ember.View.extend({
    templateName: 'Application',
    didInsertElement: function() {
      return this.addLayout();
    },
    addLayout: function() {
      $('body').layout({
        defaults: {
          minSize: 100,
          spacing_open: 3,
          closable: false,
          slidable: false,
          resizable: true,
          useStateCookie: false
        },
        north: {
          paneSelector: '#typo3-formbuilder-header',
          resizable: false,
          spacing_open: 0,
          size: 46,
          minSize: 0
        },
        east: {
          paneSelector: '#typo3-formbuilder-elementOptionsPanel',
          size: 290,
          minSize: 200,
          maxSize: 350
        },
        south: {
          paneSelector: '#typo3-formbuilder-footer',
          resizable: false,
          spacing_open: 0,
          size: 20,
          minSize: 0
        },
        west: {
          paneSelector: '#typo3-formbuilder-elementSidebar',
          size: 240,
          minSize: 200,
          maxSize: 350
        },
        center: {
          paneSelector: '#typo3-formbuilder-stage'
        }
      });
      return $('#typo3-formbuilder-elementSidebar').layout({
        defaults: {
          minSize: 100,
          closable: false,
          slidable: false,
          resizable: true,
          spacing_open: 5,
          useStateCookie: true
        },
        north: {
          minSize: 100,
          size: 300,
          paneSelector: '#typo3-formbuilder-structurePanel'
        },
        center: {
          paneSelector: '#typo3-formbuilder-insertElementsPanel'
        }
      });
    },
    updatePageTitle: (function() {
      return document.title = 'Form Builder - ' + Ember.getPath('TYPO3.FormBuilder.Model.Form.formDefinition.label');
    }).observes('TYPO3.FormBuilder.Model.Form.formDefinition.label')
  });

  TYPO3.FormBuilder.View.Header = Ember.View.extend({
    templateName: 'Header'
  });

  TYPO3.FormBuilder.View.Header.PresetSelector = Ember.Select.extend({
    contentBinding: 'TYPO3.FormBuilder.Configuration.availablePresets',
    optionLabelPath: 'content.title',
    init: function() {
      this.resetSelection();
      return this._super.apply(this, arguments);
    },
    reloadIfPresetChanged: (function() {
      var that;
      if (this.getPath('selection.name') === TYPO3.FormBuilder.Configuration.presetName) {
        return;
      }
      if (TYPO3.FormBuilder.Model.Form.get('unsavedContent')) {
        that = this;
        return $('<div>There are unsaved changes, but you need to save before changing the preset. Do you want to save now?</div>').dialog({
          dialogClass: 'typo3-formbuilder-dialog',
          title: 'Save changes?',
          modal: true,
          resizable: false,
          buttons: {
            'Save and redirect': function() {
              that.saveAndRedirect();
              return $(this).dialog('close');
            },
            'Cancel': function() {
              that.resetSelection();
              return $(this).dialog('close');
            }
          }
        });
      } else {
        return this.redirect();
      }
    }).observes('selection'),
    resetSelection: (function() {
      var val, _k, _len3, _ref7, _results;
      if (!this.get('content')) return;
      _ref7 = this.get('content');
      _results = [];
      for (_k = 0, _len3 = _ref7.length; _k < _len3; _k++) {
        val = _ref7[_k];
        if (val.name === TYPO3.FormBuilder.Configuration.presetName) {
          this.set('selection', val);
          break;
        } else {
          _results.push(void 0);
        }
      }
      return _results;
    }).observes('content'),
    saveAndRedirect: function() {
      var _this = this;
      return TYPO3.FormBuilder.Model.Form.save(function(success) {
        if (success) return _this.redirect();
      });
    },
    redirect: function() {
      return window.location.href = TYPO3.FormBuilder.Utility.getUri(TYPO3.FormBuilder.Configuration.endpoints.editForm, this.getPath('selection.name'));
    }
  });

  TYPO3.FormBuilder.View.Header.PreviewButton = Ember.Button.extend({
    targetObject: (function() {
      return this;
    }).property().cacheable(),
    action: function() {
      return this.preview();
    },
    preview: function() {
      var windowIdentifier;
      windowIdentifier = 'preview_' + TYPO3.FormBuilder.Model.Form.getPath('formDefinition.identifier');
      return window.open(TYPO3.FormBuilder.Utility.getUri(TYPO3.FormBuilder.Configuration.endpoints.previewForm), windowIdentifier);
    }
  });

  TYPO3.FormBuilder.View.Header.SaveButton = Ember.Button.extend({
    targetObject: (function() {
      return this;
    }).property().cacheable(),
    action: function() {
      return this.save();
    },
    classNames: ['typo3-formbuilder-savebutton'],
    classNameBindings: ['isActive', 'currentStatus'],
    currentStatusBinding: 'TYPO3.FormBuilder.Model.Form.saveStatus',
    disabled: (function() {
      return !Ember.getPath('TYPO3.FormBuilder.Model.Form.unsavedContent');
    }).property('TYPO3.FormBuilder.Model.Form.unsavedContent').cacheable(),
    save: function() {
      return TYPO3.FormBuilder.Model.Form.save();
    }
  });

  TYPO3.FormBuilder.View.Stage = Ember.View.extend({
    formPagesBinding: 'TYPO3.FormBuilder.Model.Form.formDefinition.renderables',
    currentPageIndex: (function() {
      var currentlySelectedRenderable, enclosingPage;
      currentlySelectedRenderable = TYPO3.FormBuilder.Model.Form.get('currentlySelectedRenderable');
      if (!currentlySelectedRenderable) return 0;
      enclosingPage = currentlySelectedRenderable.findEnclosingPage();
      if (!enclosingPage) return 0;
      if (!enclosingPage.getPath('parentRenderable.renderables')) return 0;
      return enclosingPage.getPath('parentRenderable.renderables').indexOf(enclosingPage);
    }).property('TYPO3.FormBuilder.Model.Form.currentlySelectedRenderable').cacheable(),
    page: Ember.computed(function() {
      var _ref7;
      return (_ref7 = this.get('formPages')) != null ? _ref7.get(this.get('currentPageIndex')) : void 0;
    }).property('formPages', 'currentPageIndex').cacheable(),
    currentAjaxRequest: null,
    isLoadingBinding: 'TYPO3.FormBuilder.Model.Form.currentlyLoadingPreview',
    renderPageIfPageObjectChanges: (function() {
      var _this = this;
      if (!TYPO3.FormBuilder.Model.Form.getPath('formDefinition.identifier')) {
        return;
      }
      if (this.currentAjaxRequest) this.currentAjaxRequest.abort();
      if (this.timeout) window.clearTimeout(this.timeout);
      return this.timeout = window.setTimeout(function() {
        var formDefinition;
        formDefinition = TYPO3.FormBuilder.Utility.convertToSimpleObject(TYPO3.FormBuilder.Model.Form.get('formDefinition'));
        _this.set('isLoading', true);
        return _this.currentAjaxRequest = $.post(TYPO3.FormBuilder.Configuration.endpoints.formPageRenderer, {
          formDefinition: formDefinition,
          currentPageIndex: _this.get('currentPageIndex'),
          presetName: TYPO3.FormBuilder.Configuration.presetName
        }, function(data, textStatus, jqXHR) {
          if (_this.currentAjaxRequest !== jqXHR) return;
          _this.$().html(data);
          _this.set('isLoading', false);
          return _this.postProcessRenderedPage();
        });
      }, 300);
    }).observes('page', 'page.__nestedPropertyChange'),
    postProcessRenderedPage: function() {
      var _this = this;
      this.onCurrentElementChanges();
      this.$().find('[data-element]').on('click dblclick select focus keydown keypress keyup mousedown mouseup', function(e) {
        return e.preventDefault();
      });
      this.$().find('form').submit(function(e) {
        return e.preventDefault();
      });
      return this.$().find('[data-element]').parent().addClass('typo3-form-sortable').sortable({
        revert: 'true',
        start: function(e, o) {
          if (_this.currentAjaxRequest) _this.currentAjaxRequest.abort();
          if (_this.timeout) window.clearTimeout(_this.timeout);
          return _this.set('isLoading', false);
        },
        update: function(e, o) {
          var movedRenderable, nextElement, nextElementPath, pathOfMovedElement, previousElement, previousElementPath, referenceElementIndex;
          pathOfMovedElement = $(o.item.context).attr('data-element');
          movedRenderable = _this.findRenderableForPath(pathOfMovedElement);
          movedRenderable.getPath('parentRenderable.renderables').removeObject(movedRenderable);
          nextElementPath = $(o.item.context).nextAll('[data-element]').first().attr('data-element');
          if (nextElementPath) {
            nextElement = _this.findRenderableForPath(nextElementPath);
          }
          previousElementPath = $(o.item.context).prevAll('[data-element]').first().attr('data-element');
          if (previousElementPath) {
            previousElement = _this.findRenderableForPath(previousElementPath);
          }
          if (nextElement) {
            referenceElementIndex = nextElement.getPath('parentRenderable.renderables').indexOf(nextElement);
            return nextElement.getPath('parentRenderable.renderables').insertAt(referenceElementIndex, movedRenderable);
          } else if (previousElement) {
            referenceElementIndex = previousElement.getPath('parentRenderable.renderables').indexOf(previousElement);
            return previousElement.getPath('parentRenderable.renderables').insertAt(referenceElementIndex + 1, movedRenderable);
          } else {
            throw 'Next Element or Previous Element need to be set. Should not happen...';
          }
        }
      });
    },
    onCurrentElementChanges: (function() {
      var identifierPath, renderable;
      renderable = TYPO3.FormBuilder.Model.Form.get('currentlySelectedRenderable');
      if (!renderable) return;
      this.$().find('.typo3-formbuilder-form-element-selected').removeClass('typo3-formbuilder-form-element-selected');
      identifierPath = renderable.identifier;
      while (renderable = renderable.parentRenderable) {
        identifierPath = renderable.identifier + '/' + identifierPath;
      }
      return this.$().find('[data-element="' + identifierPath + '"]').addClass('typo3-formbuilder-form-element-selected');
    }).observes('TYPO3.FormBuilder.Model.Form.currentlySelectedRenderable'),
    click: function(e) {
      var pathToClickedElement;
      pathToClickedElement = $(e.target).closest('[data-element]').attr('data-element');
      if (!pathToClickedElement) return;
      return TYPO3.FormBuilder.Model.Form.set('currentlySelectedRenderable', this.findRenderableForPath(pathToClickedElement));
    },
    findRenderableForPath: function(path) {
      var currentRenderable, expandedPathToClickedElement, pathPart, renderable, _k, _l, _len3, _len4, _ref7;
      expandedPathToClickedElement = path.split('/');
      expandedPathToClickedElement.shift();
      expandedPathToClickedElement.shift();
      currentRenderable = this.get('page');
      for (_k = 0, _len3 = expandedPathToClickedElement.length; _k < _len3; _k++) {
        pathPart = expandedPathToClickedElement[_k];
        _ref7 = currentRenderable.get('renderables');
        for (_l = 0, _len4 = _ref7.length; _l < _len4; _l++) {
          renderable = _ref7[_l];
          if (renderable.identifier === pathPart) {
            currentRenderable = renderable;
            break;
          }
        }
      }
      return currentRenderable;
    }
  });

  TYPO3.FormBuilder.View.StructurePanel = Ember.View.extend({
    formDefinitionBinding: 'TYPO3.FormBuilder.Model.Form.formDefinition',
    templateName: 'StructurePanel',
    _tree: null,
    didInsertElement: function() {
      this._tree = this.$().find('.tree');
      this._tree.dynatree({
        onActivate: function(node) {
          return TYPO3.FormBuilder.Model.Form.set('currentlySelectedRenderable', node.data.formRenderable);
        },
        dnd: {
          onDragStart: function() {
            return true;
          },
          autoExpandMS: 300,
          onDragEnter: function(targetNode, sourceNode) {
            var targetNodeIsCompositeRenderable;
            targetNodeIsCompositeRenderable = targetNode.data.formRenderable.getPath('typeDefinition.formBuilder._isCompositeRenderable');
            if (sourceNode.getLevel() === 1) {
              if (targetNode.getLevel() === 1) {
                return ['before', 'after'];
              } else {
                return false;
              }
            } else {
              if (targetNode.getLevel() === 1) {
                if (targetNode.data.formRenderable.getPath('typeDefinition.formBuilder._isCompositeRenderable')) {
                  return ['over'];
                } else {
                  return false;
                }
              } else {
                if (targetNodeIsCompositeRenderable) {
                  return ['before', 'over', 'after'];
                } else {
                  return ['before', 'after'];
                }
              }
            }
          },
          onDrop: function(targetNode, sourceNode, hitMode) {
            var indexOfTargetRenderable, sourceRenderable, targetRenderable;
            sourceRenderable = sourceNode.data.formRenderable;
            targetRenderable = targetNode.data.formRenderable;
            sourceRenderable.getPath('parentRenderable.renderables').removeObject(sourceRenderable);
            if (hitMode === 'over') {
              targetRenderable.get('renderables').pushObject(sourceRenderable);
            } else {
              indexOfTargetRenderable = targetRenderable.getPath('parentRenderable.renderables').indexOf(targetRenderable);
              if (hitMode === 'before') {
                targetRenderable.getPath('parentRenderable.renderables').insertAt(indexOfTargetRenderable, sourceRenderable);
              } else {
                targetRenderable.getPath('parentRenderable.renderables').insertAt(indexOfTargetRenderable + 1, sourceRenderable);
              }
            }
            TYPO3.FormBuilder.Model.Form.set('currentlySelectedRenderable', null);
            return TYPO3.FormBuilder.Model.Form.set('currentlySelectedRenderable', sourceRenderable);
          }
        }
      });
      return this.updateTreeStateFromModel(this._tree.dynatree('getRoot'), this.getPath('formDefinition.renderables'));
    },
    updateTree: (function() {
      var activeNodePath, expandedNodePath, expandedNodePaths, _base, _base2, _k, _len3, _ref7, _ref8, _ref9;
      if (!((_ref7 = this._tree) != null ? _ref7.dynatree('getTree').visit : void 0)) {
        return;
      }
      expandedNodePaths = [];
      this._tree.dynatree('getTree').visit(function(node) {
        if (node.isExpanded()) return expandedNodePaths.push(node.data.key);
      });
      if (typeof (_base = this._tree.dynatree('getRoot')).removeChildren === "function") {
        _base.removeChildren();
      }
      this.updateTreeStateFromModel(this._tree.dynatree('getRoot'), this.getPath('formDefinition.renderables'), expandedNodePaths.length === 0);
      for (_k = 0, _len3 = expandedNodePaths.length; _k < _len3; _k++) {
        expandedNodePath = expandedNodePaths[_k];
        if ((_ref8 = this._tree.dynatree('getTree').getNodeByKey(expandedNodePath)) != null) {
          _ref8.expand(true);
        }
      }
      activeNodePath = TYPO3.FormBuilder.Model.Form.getPath('currentlySelectedRenderable._path');
      return typeof (_base2 = this._tree.dynatree('getTree')).getNodeByKey === "function" ? (_ref9 = _base2.getNodeByKey(activeNodePath)) != null ? _ref9.activate(true) : void 0 : void 0;
    }).observes('formDefinition.__nestedPropertyChange'),
    updateTreeStateFromModel: function(dynaTreeParentNode, currentListOfSubRenderables, expandFirstNode) {
      var i, newNode, nodeOptions, subRenderable, _len3, _results;
      if (expandFirstNode == null) expandFirstNode = false;
      if (!currentListOfSubRenderables) return;
      _results = [];
      for (i = 0, _len3 = currentListOfSubRenderables.length; i < _len3; i++) {
        subRenderable = currentListOfSubRenderables[i];
        nodeOptions = {
          key: subRenderable.get('_path'),
          title: "" + (subRenderable.label ? subRenderable.label : subRenderable.identifier) + " <em>(" + (subRenderable.getPath('typeDefinition.formBuilder.label')) + ")</em>",
          formRenderable: subRenderable,
          addClass: subRenderable.getPath('typeDefinition.__cssClassNames')
        };
        if (expandFirstNode && i === 0) nodeOptions.expand = true;
        newNode = dynaTreeParentNode.addChild(nodeOptions);
        _results.push(this.updateTreeStateFromModel(newNode, subRenderable.getPath('renderables')));
      }
      return _results;
    },
    updateCurrentlySelectedNode: (function() {
      return this.updateTree();
    }).observes('TYPO3.FormBuilder.Model.Form.currentlySelectedRenderable'),
    showFormOptions: function() {
      return TYPO3.FormBuilder.Model.Form.set('currentlySelectedRenderable', TYPO3.FormBuilder.Model.Form.get('formDefinition'));
    }
  });

  TYPO3.FormBuilder.View.StructurePanel.FormButton = Ember.Button.extend({
    target: 'parentView',
    action: 'showFormOptions',
    classNameBindings: ['isFormDefinitionCurrentlySelected:typo3-formbuilder-form-selected'],
    isFormDefinitionCurrentlySelected: (function() {
      return Ember.getPath('TYPO3.FormBuilder.Model.Form.currentlySelectedRenderable') === Ember.getPath('TYPO3.FormBuilder.Model.Form.formDefinition');
    }).property('TYPO3.FormBuilder.Model.Form.formDefinition', 'TYPO3.FormBuilder.Model.Form.currentlySelectedRenderable').cacheable()
  });

  TYPO3.FormBuilder.View.InsertElementsPanel = Ember.View.extend({
    templateName: 'InsertElementsPanel',
    allFormElementTypesBinding: 'TYPO3.FormBuilder.Model.FormElementTypes.allTypeNames',
    formElementsGrouped: (function() {
      var formElementType, formElementTypeName, formElementsByGroup, formGroup, formGroupName, formGroups, _k, _l, _len3, _len4, _ref10, _ref7, _ref8, _ref9;
      formElementsByGroup = {};
      _ref7 = this.get('allFormElementTypes');
      for (_k = 0, _len3 = _ref7.length; _k < _len3; _k++) {
        formElementTypeName = _ref7[_k];
        formElementType = TYPO3.FormBuilder.Model.FormElementTypes.get(formElementTypeName);
        if (((_ref8 = formElementType.formBuilder) != null ? _ref8.group : void 0) == null) {
          continue;
        }
        if (!formElementsByGroup[formElementType.formBuilder.group]) {
          formElementsByGroup[formElementType.formBuilder.group] = [];
        }
        formElementType.set('key', formElementTypeName);
        formElementsByGroup[formElementType.formBuilder.group].push(formElementType);
      }
      formGroups = [];
      _ref9 = TYPO3.FormBuilder.Model.FormElementGroups.get('allGroupNames');
      for (_l = 0, _len4 = _ref9.length; _l < _len4; _l++) {
        formGroupName = _ref9[_l];
        formGroup = TYPO3.FormBuilder.Model.FormElementGroups.get(formGroupName);
        formGroup.set('key', formGroupName);
        if ((_ref10 = formElementsByGroup[formGroupName]) != null) {
          _ref10.sort(function(a, b) {
            return a.formBuilder.sorting - b.formBuilder.sorting;
          });
        }
        formGroup.set('elements', formElementsByGroup[formGroupName]);
        formGroups.push(formGroup);
      }
      formGroups.sort(function(a, b) {
        return a.sorting - b.sorting;
      });
      return formGroups;
    }).property('allFormElementTypes').cacheable()
  });

  TYPO3.FormBuilder.View.InsertElementsPanel.ElementsCollection = Ember.CollectionView.extend({
    itemViewClass: 'TYPO3.FormBuilder.View.InsertElementsPanel.Element'
  });

  TYPO3.FormBuilder.View.InsertElementsPanel.Element = Ember.View.extend({
    currentlySelectedElementBinding: 'TYPO3.FormBuilder.Model.Form.currentlySelectedRenderable',
    content: null,
    formElementTypeBinding: 'content',
    didInsertElement: function() {
      this.$().html('<span>' + this.getPath('formElementType.formBuilder.label') + '</span>');
      this.$().attr('title', this.getPath('formElementType.key'));
      return this.$().addClass(this.getPath('formElementType.__cssClassNames'));
    },
    classNameBindings: ['enabled:typo3-formbuilder-enabled'],
    enabled: (function() {
      var currentlySelectedRenderable;
      if (this.getPath('formElementType.formBuilder._isTopLevel')) return true;
      currentlySelectedRenderable = this.get('currentlySelectedElement');
      if (!currentlySelectedRenderable) return false;
      if (currentlySelectedRenderable.getPath('typeDefinition.formBuilder._isTopLevel') && !currentlySelectedRenderable.getPath('typeDefinition.formBuilder._isCompositeRenderable')) {
        return false;
      }
      return true;
    }).property('formElementType', 'currentlySelectedElement').cacheable(),
    getNextFreeIdentifier: function() {
      var i, isIdentifierUsed, prefix, type;
      type = this.getPath('formElementType.key');
      prefix = type.split(':')[1];
      prefix = prefix.toLowerCase();
      isIdentifierUsed = function(identifier) {
        var checkIdentifier, identifierFound;
        identifierFound = false;
        checkIdentifier = function(renderable) {
          var childRenderable, _k, _len3, _ref7, _results;
          if (renderable.get('identifier') === identifier) identifierFound = true;
          if (!identifierFound) {
            _ref7 = renderable.get('renderables');
            _results = [];
            for (_k = 0, _len3 = _ref7.length; _k < _len3; _k++) {
              childRenderable = _ref7[_k];
              _results.push(checkIdentifier(childRenderable));
            }
            return _results;
          }
        };
        checkIdentifier(TYPO3.FormBuilder.Model.Form.get('formDefinition'));
        return identifierFound;
      };
      i = 1;
      while (isIdentifierUsed(prefix + i)) {
        i++;
      }
      return prefix + i;
    },
    click: function() {
      var currentlySelectedRenderable, defaultValues, identifier, indexInParent, newRenderable, parentRenderablesArray, referenceRenderable,
        _this = this;
      currentlySelectedRenderable = this.get('currentlySelectedElement');
      if (!currentlySelectedRenderable) return;
      if (!this.get('enabled')) return;
      defaultValues = this.getPath('formElementType.formBuilder.predefinedDefaults') || {};
      identifier = this.getNextFreeIdentifier();
      newRenderable = TYPO3.FormBuilder.Model.Renderable.create($.extend({
        type: this.getPath('formElementType.key'),
        identifier: identifier,
        label: identifier
      }, defaultValues));
      if (!this.getPath('formElementType.formBuilder._isTopLevel') && currentlySelectedRenderable.getPath('typeDefinition.formBuilder._isCompositeRenderable')) {
        currentlySelectedRenderable.get('renderables').pushObject(newRenderable);
      } else {
        referenceRenderable = currentlySelectedRenderable;
        if (referenceRenderable === TYPO3.FormBuilder.Model.Form.get('formDefinition')) {
          referenceRenderable = referenceRenderable.getPath('renderables.0');
        } else if (this.getPath('formElementType.formBuilder._isTopLevel') && !currentlySelectedRenderable.getPath('typeDefinition.formBuilder._isTopLevel')) {
          referenceRenderable = referenceRenderable.findEnclosingPage();
        } else if (this.getPath('formElementType.formBuilder._isCompositeRenderable')) {
          if (referenceRenderable.findEnclosingCompositeRenderableWhichIsNotOnTopLevel()) {
            referenceRenderable = referenceRenderable.findEnclosingCompositeRenderableWhichIsNotOnTopLevel();
          }
        }
        parentRenderablesArray = referenceRenderable.getPath('parentRenderable.renderables');
        indexInParent = parentRenderablesArray.indexOf(referenceRenderable);
        parentRenderablesArray.replace(indexInParent + 1, 0, [newRenderable]);
      }
      return window.setTimeout(function() {
        return _this.set('currentlySelectedElement', newRenderable);
      }, 10);
    }
  });

  TYPO3.FormBuilder.View.ElementOptionsPanel = Ember.ContainerView.extend({
    formElement: null,
    orderedFormFieldEditors: (function() {
      var formFieldEditors, k, orderedFormFieldEditors, v;
      formFieldEditors = $.extend({}, this.getPath('formElement.typeDefinition.formBuilder.editors'));
      orderedFormFieldEditors = [];
      for (k in formFieldEditors) {
        v = formFieldEditors[k];
        if (!v) continue;
        v['key'] = k;
        orderedFormFieldEditors.push(v);
      }
      orderedFormFieldEditors.sort(function(a, b) {
        return a.sorting - b.sorting;
      });
      return orderedFormFieldEditors;
    }).property('formElement.typeDefinition').cacheable(),
    onFormElementChange: (function() {
      var formFieldEditor, subView, subViewClass, subViewOptions, _k, _len3, _ref7, _results;
      this.removeAllChildren();
      if (!this.formElement) return;
      _ref7 = this.get('orderedFormFieldEditors');
      _results = [];
      for (_k = 0, _len3 = _ref7.length; _k < _len3; _k++) {
        formFieldEditor = _ref7[_k];
        subViewClass = Ember.getPath(formFieldEditor.viewName);
        if (!subViewClass) {
          throw "Editor class '" + formFieldEditor.viewName + "' not found";
        }
        subViewOptions = $.extend({}, formFieldEditor, {
          formElement: this.formElement
        });
        subView = subViewClass.create(subViewOptions);
        _results.push(this.get('childViews').pushObject(subView));
      }
      return _results;
    }).observes('formElement')
  });

  TYPO3.FormBuilder.View.ElementOptionsPanel.Editor = {};

  TYPO3.FormBuilder.View.ElementOptionsPanel.Editor.AbstractEditor = Ember.View.extend({
    classNames: ['form-editor'],
    formElement: null
  });

  TYPO3.FormBuilder.View.ElementOptionsPanel.Editor.AbstractPropertyEditor = TYPO3.FormBuilder.View.ElementOptionsPanel.Editor.AbstractEditor.extend({
    propertyPath: null,
    defaultValue: '',
    valueChanged: function() {
      var _base;
      return typeof (_base = this.get('formElement')).somePropertyChanged === "function" ? _base.somePropertyChanged(this.formElement, this.get('propertyPath')) : void 0;
    },
    value: (function(k, v) {
      var value;
      if (v !== void 0) {
        this.formElement.setPath(this.get('propertyPath'), v);
        return v;
      } else {
        value = this.formElement.getPath(this.get('propertyPath'));
        if (value === void 0) {
          this.formElement.setPathRecursively(this.get('propertyPath'), this.get('defaultValue'));
          value = this.formElement.getPath(this.get('propertyPath'));
        }
        return value;
      }
    }).property('propertyPath', 'formElement').cacheable()
  });

  TYPO3.FormBuilder.View.ElementOptionsPanel.Editor.AbstractCollectionEditor = TYPO3.FormBuilder.View.ElementOptionsPanel.Editor.AbstractPropertyEditor.extend({
    availableCollectionElements: null,
    defaultValue: (function() {
      return [];
    }).property().cacheable(),
    isVisible: (function() {
      var collectionEditorViewsFound, collectionElementsAvailable;
      collectionElementsAvailable = !this.get('noCollectionElementsAvailable');
      collectionEditorViewsFound = this.get('collectionEditorViews').length > 0;
      return collectionElementsAvailable || collectionEditorViewsFound;
    }).property('collectionEditorViews', 'noCollectionElementsAvailable').cacheable(),
    collectionEditorViews: null,
    prompt: Ember.required(),
    init: function() {
      this._super();
      this.set('collectionEditorViews', []);
      return this.updateCollectionEditorViews();
    },
    sortedAvailableCollectionElements: (function() {
      var collectionElementTemplate, identifier, sortedCollectionElements, _ref7;
      sortedCollectionElements = [];
      _ref7 = this.get('availableCollectionElements');
      for (identifier in _ref7) {
        collectionElementTemplate = _ref7[identifier];
        if (this.isCollectionElementTemplateFoundInCollection(identifier)) {
          continue;
        }
        sortedCollectionElements.push($.extend({
          identifier: identifier
        }, collectionElementTemplate));
      }
      sortedCollectionElements.sort(function(a, b) {
        return a.sorting - b.sorting;
      });
      return sortedCollectionElements;
    }).property('availableCollectionElements', 'formElement.__nestedPropertyChange').cacheable(),
    noCollectionElementsAvailable: (function() {
      return this.get('sortedAvailableCollectionElements').length === 0;
    }).property('sortedAvailableCollectionElements').cacheable(),
    addCollectionElementSelection: null,
    addCollectionElement: (function() {
      var collectionElementToBeAdded;
      collectionElementToBeAdded = this.get('addCollectionElementSelection');
      if (!collectionElementToBeAdded) return;
      this.get('value').push({
        identifier: collectionElementToBeAdded.identifier,
        options: collectionElementToBeAdded.options || {}
      });
      this.valueChanged();
      this.updateCollectionEditorViews();
      return this.set('addCollectionElementSelection', null);
    }).observes('addCollectionElementSelection'),
    updateCollectionEditorViews: (function() {
      var availableCollectionElements, collection, collectionEditorViews, collectionElement, collectionElementEditor, collectionElementEditorOptions, collectionElementTemplate, i, _len3,
        _this = this;
      this.addRequiredCollectionElementsIfNeeded();
      collection = this.get('value');
      availableCollectionElements = this.get('availableCollectionElements');
      if (!availableCollectionElements) return;
      collectionEditorViews = [];
      for (i = 0, _len3 = collection.length; i < _len3; i++) {
        collectionElement = collection[i];
        collectionElementTemplate = availableCollectionElements[collectionElement.identifier];
        if (!collectionElementTemplate) continue;
        collectionElementEditor = Ember.getPath(collectionElementTemplate.viewName || 'TYPO3.FormBuilder.View.ElementOptionsPanel.Editor.ValidatorEditor.DefaultValidatorEditor');
        if (!collectionElementEditor) {
          throw "Collection Editor class '" + collectionElementTemplate.viewName + "' not found";
        }
        collectionElementEditorOptions = $.extend({
          elementIndex: i,
          valueChanged: function() {
            return _this.valueChanged();
          },
          updateCollectionEditorViews: function() {
            return _this.updateCollectionEditorViews();
          },
          collection: this.get('value')
        }, collectionElementTemplate);
        collectionEditorViews.push(collectionElementEditor.create(collectionElementEditorOptions));
      }
      return this.set('collectionEditorViews', collectionEditorViews);
    }).observes('value', 'availableCollectionElements'),
    addRequiredCollectionElementsIfNeeded: function() {
      var availableCollectionElementTemplate, availableCollectionElements, collection, collectionElementName, identifier, requiredAndMissingCollectionElements, _k, _len3, _results;
      collection = this.get('value');
      availableCollectionElements = this.get('availableCollectionElements');
      requiredAndMissingCollectionElements = [];
      for (identifier in availableCollectionElements) {
        availableCollectionElementTemplate = availableCollectionElements[identifier];
        if (!availableCollectionElementTemplate.required) continue;
        if (!this.isCollectionElementTemplateFoundInCollection(identifier)) {
          requiredAndMissingCollectionElements.push(identifier);
        }
      }
      _results = [];
      for (_k = 0, _len3 = requiredAndMissingCollectionElements.length; _k < _len3; _k++) {
        collectionElementName = requiredAndMissingCollectionElements[_k];
        _results.push(collection.push({
          identifier: collectionElementName,
          options: $.extend({}, availableCollectionElements[collectionElementName].options)
        }));
      }
      return _results;
    },
    isCollectionElementTemplateFoundInCollection: function(collectionElementTemplateIdentifier) {
      var collection, collectionElement, _k, _len3;
      collection = this.get('value');
      for (_k = 0, _len3 = collection.length; _k < _len3; _k++) {
        collectionElement = collection[_k];
        if (collectionElementTemplateIdentifier === collectionElement.identifier) {
          return true;
        }
      }
      return false;
    }
  });

  TYPO3.FormBuilder.View.ElementOptionsPanel.Editor.TextOutput = TYPO3.FormBuilder.View.ElementOptionsPanel.Editor.AbstractEditor.extend({});

  TYPO3.FormBuilder.View.ElementOptionsPanel.Editor.IdentifierEditor = TYPO3.FormBuilder.View.ElementOptionsPanel.Editor.AbstractPropertyEditor.extend({
    templateName: 'ElementOptionsPanel-IdentifierEditor',
    propertyPath: 'identifier',
    editMode: false,
    textFieldValue: null,
    validationErrorMessage: null,
    validate: function(v) {
      var elementsWithIdentifier, findFormElementsWithIdentifiers;
      if (v === '') {
        this.set('validationErrorMessage', 'You need to set an identifier!');
        return false;
      }
      if (!v.match(/^[a-z][a-zA-Z0-9-_]*$/)) {
        this.set('validationErrorMessage', 'This is no valid identifier. Only lowerCamelCase allowed.');
        return false;
      }
      elementsWithIdentifier = [];
      findFormElementsWithIdentifiers = function(el) {
        var subRenderable, _k, _len3, _ref7, _results;
        if (el.get('identifier') === v) elementsWithIdentifier.push(el);
        _ref7 = el.get('renderables');
        _results = [];
        for (_k = 0, _len3 = _ref7.length; _k < _len3; _k++) {
          subRenderable = _ref7[_k];
          _results.push(findFormElementsWithIdentifiers(subRenderable));
        }
        return _results;
      };
      findFormElementsWithIdentifiers(TYPO3.FormBuilder.Model.Form.get('formDefinition'));
      if (elementsWithIdentifier.length === 0) {
        this.set('validationErrorMessage', null);
        return true;
      } else if (elementsWithIdentifier.length === 1 && elementsWithIdentifier[0] === this.get('formElement')) {
        this.set('validationErrorMessage', null);
        return true;
      } else {
        this.set('validationErrorMessage', 'The identifier is already used');
        return false;
      }
    },
    commit: function() {
      if (this.validate(this.get('textFieldValue'))) {
        this.set('value', this.get('textFieldValue'));
        this.set('editMode', false);
        return true;
      } else {
        return false;
      }
    },
    tryToCommit: function() {
      if (!this.commit()) return this.abort();
    },
    abort: function() {
      return this.set('editMode', false);
    },
    click: function() {
      if (!this.get('editMode')) {
        this.set('textFieldValue', this.get('value'));
        return this.set('editMode', true);
      }
    }
  });

  TYPO3.FormBuilder.View.ElementOptionsPanel.Editor.IdentifierEditor.TextField = Ember.TextField.extend({
    insertNewline: function() {
      return this.get('parentView').commit();
    },
    cancel: function() {
      return this.get('parentView').abort();
    },
    focusOut: function() {
      return this.get('parentView').tryToCommit();
    },
    didInsertElement: function() {
      return this.$().select();
    }
  });

  TYPO3.FormBuilder.View.ElementOptionsPanel.Editor.TextEditor = TYPO3.FormBuilder.View.ElementOptionsPanel.Editor.AbstractPropertyEditor.extend({
    label: null,
    onValueChange: (function() {
      return this.valueChanged();
    }).observes('value'),
    templateName: 'ElementOptionsPanel-TextEditor'
  });

  TYPO3.FormBuilder.View.ElementOptionsPanel.Editor.TextareaEditor = TYPO3.FormBuilder.View.ElementOptionsPanel.Editor.TextEditor.extend({
    templateName: 'ElementOptionsPanel-TextareaEditor'
  });

  TYPO3.FormBuilder.View.ElementOptionsPanel.Editor.SelectEditor = TYPO3.FormBuilder.View.ElementOptionsPanel.Editor.AbstractPropertyEditor.extend({
    templateName: 'ElementOptionsPanel-SelectEditor',
    availableElements: null,
    selectedValue: (function(k, v) {
      var element, _k, _len3, _ref7;
      if (arguments.length >= 2) {
        this.set('value', v.value);
        this.valueChanged();
      }
      _ref7 = this.get('availableElements');
      for (_k = 0, _len3 = _ref7.length; _k < _len3; _k++) {
        element = _ref7[_k];
        if (element.value === this.get('value')) return element;
      }
      return null;
    }).property('availableElements', 'value').cacheable()
  });

  TYPO3.FormBuilder.View.ElementOptionsPanel.Editor.RemoveElementEditor = TYPO3.FormBuilder.View.ElementOptionsPanel.Editor.AbstractEditor.extend({
    templateName: 'ElementOptionsPanel-RemoveElement',
    remove: function() {
      return this.get('formElement').removeWithConfirmationDialog();
    }
  });

  TYPO3.FormBuilder.View.ElementOptionsPanel.Editor.PropertyGrid = TYPO3.FormBuilder.View.ElementOptionsPanel.Editor.AbstractPropertyEditor.extend({
    columns: null,
    isSortable: false,
    enableAddRow: false,
    enableDeleteRow: false,
    shouldShowPreselectedValueColumn: false,
    templateName: 'ElementOptionsPanel-PropertyGridEditor',
    defaultValue: (function() {
      return [];
    }).property().cacheable(),
    options: (function() {
      return {
        enableColumnReorder: false,
        autoHeight: true,
        editable: true,
        enableAddRow: this.get('enableAddRow'),
        enableCellNavigation: true,
        asyncEditorLoading: false,
        forceFitColumns: true
      };
    }).property('enableAddRow').cacheable(),
    columnDefinition: (function() {
      var column, columns, _k, _len3, _ref7;
      columns = [];
      if (this.get('isSortable')) {
        columns.push({
          id: "#",
          name: "",
          width: 40,
          behavior: "selectAndMove",
          selectable: false,
          resizable: false,
          cssClass: "cell-reorder dnd",
          focusable: false
        });
      }
      _ref7 = this.get('columns');
      for (_k = 0, _len3 = _ref7.length; _k < _len3; _k++) {
        column = _ref7[_k];
        column = $.extend({}, column);
        column.id = column.field;
        column.editor = Ember.getPath(column.editor);
        columns.push(column);
      }
      if (this.get('shouldShowPreselectedValueColumn')) {
        columns.push({
          id: '__preselectedValues',
          field: '__isPreselected',
          name: 'Selected',
          selectable: false,
          resizable: false,
          formatter: YesNoCellFormatter,
          editor: YesNoCheckboxCellEditor
        });
      }
      if (this.get('enableDeleteRow')) {
        columns.push({
          id: '__delete',
          name: '',
          width: 16,
          selectable: false,
          resizable: false,
          focusable: false,
          cssClass: "typo3-formbuilder-grid-deleteRow"
        });
      }
      return columns;
    }).property('columns', 'isSortable').cacheable(),
    tableRowModel: null,
    buildTableRowModel: (function() {
      var defaultValue, isPreselected, originalRow, tableRowModel, v, _k, _l, _len3, _len4, _ref7, _results;
      if (!this.get('tableRowModel')) this.set('tableRowModel', []);
      tableRowModel = this.get('tableRowModel');
      if (tableRowModel.get('length') > 0) {
        tableRowModel.removeAt(0, tableRowModel.get('length'));
      }
      if (this.get('shouldShowPreselectedValueColumn') === 'multiple') {
        defaultValue = this.getPath('formElement.defaultValue') || [];
      } else if (this.get('shouldShowPreselectedValueColumn') === 'single' && this.getPath('formElement.defaultValue')) {
        defaultValue = [this.getPath('formElement.defaultValue')];
      } else {
        defaultValue = [];
      }
      _ref7 = this.get('value');
      _results = [];
      for (_k = 0, _len3 = _ref7.length; _k < _len3; _k++) {
        originalRow = _ref7[_k];
        isPreselected = false;
        for (_l = 0, _len4 = defaultValue.length; _l < _len4; _l++) {
          v = defaultValue[_l];
          if (v === originalRow._key) isPreselected = true;
        }
        _results.push(tableRowModel.push($.extend({
          __isPreselected: isPreselected
        }, originalRow)));
      }
      return _results;
    }),
    valueChanged: function() {
      var defaultValue, i, oldDefaultValue, rows, tableRowModelRow, tmp, v, _k, _len3, _len4, _ref7;
      rows = [];
      defaultValue = [];
      _ref7 = this.get('tableRowModel');
      for (_k = 0, _len3 = _ref7.length; _k < _len3; _k++) {
        tableRowModelRow = _ref7[_k];
        if (tableRowModelRow.__isPreselected) {
          defaultValue.push(tableRowModelRow._key);
        }
        tmp = $.extend({}, tableRowModelRow);
        delete tmp.__isPreselected;
        rows.push(tmp);
      }
      if (this.get('shouldShowPreselectedValueColumn') === 'multiple') {
        this.setPath('formElement.defaultValue', defaultValue);
        this.set('value', rows);
      } else if (this.get('shouldShowPreselectedValueColumn') === 'single') {
        this.set('value', rows);
        if (defaultValue.length === 0) {
          this.setPath('formElement.defaultValue', null);
        } else {
          oldDefaultValue = this.getPath('formElement.defaultValue');
          for (i = 0, _len4 = defaultValue.length; i < _len4; i++) {
            v = defaultValue[i];
            if (v !== oldDefaultValue) this.setPath('formElement.defaultValue', v);
          }
        }
        this.buildTableRowModel();
        this.grid.invalidateAllRows();
        this.grid.render();
      } else {
        this.set('value', rows);
      }
      return this._super();
    },
    grid: null,
    init: function() {
      this.classNames.push('PropertyGrid');
      return this._super();
    },
    didInsertElement: function() {
      var moveRowsPlugin,
        _this = this;
      this.buildTableRowModel();
      this.grid = new Slick.Grid(this.$().find('.typo3-formbuilder-grid'), this.get('tableRowModel'), this.get('columnDefinition'), this.get('options'));
      this.$().find('.slick-viewport').css('overflow-x', 'hidden');
      this.$().find('.slick-viewport').css('overflow-y', 'hidden');
      this.grid.setSelectionModel(new Slick.RowSelectionModel());
      this.grid.onDragInit.subscribe(function() {
        return _this.grid.getEditorLock().commitCurrentEdit();
      });
      this.grid.onCellChange.subscribe(function(e, args) {
        _this.get('tableRowModel').replace(args.row, 1, args.item);
        return _this.valueChanged();
      });
      this.grid.onAddNewRow.subscribe(function(e, args) {
        var columnDefinition, newItem, _k, _len3, _ref7;
        _this.grid.invalidateRow(_this.get('tableRowModel').length);
        newItem = {};
        _ref7 = _this.columns;
        for (_k = 0, _len3 = _ref7.length; _k < _len3; _k++) {
          columnDefinition = _ref7[_k];
          newItem[columnDefinition.field] = '';
        }
        $.extend(newItem, args.item);
        _this.get('tableRowModel').pushObject(newItem);
        _this.grid.updateRowCount();
        _this.grid.render();
        return _this.valueChanged();
      });
      moveRowsPlugin = new Slick.RowMoveManager();
      this.grid.registerPlugin(moveRowsPlugin);
      moveRowsPlugin.onBeforeMoveRows.subscribe(function(e, data) {
        var i, _ref7;
        for (i = 0, _ref7 = data.rows.length; 0 <= _ref7 ? i < _ref7 : i > _ref7; 0 <= _ref7 ? i++ : i--) {
          if (data.rows[i] === data.insertBefore || data.rows[i] === data.insertBefore - 1) {
            e.stopPropagation();
            return false;
          }
        }
        return true;
      });
      moveRowsPlugin.onMoveRows.subscribe(function(e, args) {
        var arrayRowToBeMoved, movedRowIndex;
        movedRowIndex = args.rows[0];
        arrayRowToBeMoved = _this.get('tableRowModel').objectAt(movedRowIndex);
        _this.get('tableRowModel').removeAt(movedRowIndex, 1);
        if (movedRowIndex < args.insertBefore) args.insertBefore--;
        _this.get('tableRowModel').insertAt(args.insertBefore, arrayRowToBeMoved);
        _this.valueChanged();
        _this.grid.invalidateAllRows();
        return _this.grid.render();
      });
      if (this.get('enableDeleteRow')) {
        return this.grid.onClick.subscribe(function(e, args) {
          if (_this.get('enableDeleteRow') && args.cell === _this.get('columnDefinition').length - 1) {
            if (args.row >= _this.getPath('tableRowModel.length')) return;
            _this.get('tableRowModel').removeAt(args.row);
            _this.grid.invalidateAllRows();
            _this.grid.render();
            _this.grid.resizeCanvas();
            return _this.valueChanged();
          }
        });
      }
    }
  });

  TYPO3.FormBuilder.View.ElementOptionsPanel.Editor.PropertyGrid.TextCellEditor = function(args) {
    var retVal;
    retVal = window.TextCellEditor.apply(this, arguments);
    $(args.container).children('.editor-text').focusout(function() {
      return Slick.GlobalEditorLock.commitCurrentEdit();
    });
    return retVal;
  };

  TYPO3.FormBuilder.View.ElementOptionsPanel.Editor.RequiredValidatorEditor = TYPO3.FormBuilder.View.ElementOptionsPanel.Editor.AbstractPropertyEditor.extend({
    templateName: 'ElementOptionsPanel-RequiredValidatorEditor',
    propertyPath: 'validators',
    defaultValue: (function() {
      return [];
    }).property().cacheable(),
    isRequiredValidatorConfigured: (function(k, v) {
      var a, notEmptyValidatorIdentifier, val;
      notEmptyValidatorIdentifier = 'TYPO3.FLOW3:NotEmpty';
      if (v !== void 0) {
        a = this.get('value').filter(function(validatorConfiguration) {
          return validatorConfiguration.identifier !== notEmptyValidatorIdentifier;
        });
        this.set('value', a);
        if (v === true) {
          this.get('value').push({
            identifier: notEmptyValidatorIdentifier
          });
        }
        this.valueChanged();
        return v;
      } else {
        val = !!this.get('value').some(function(validatorConfiguration) {
          return validatorConfiguration.identifier === notEmptyValidatorIdentifier;
        });
        return val;
      }
    }).property('value').cacheable()
  });

  TYPO3.FormBuilder.View.ElementOptionsPanel.Editor.ValidatorEditor = TYPO3.FormBuilder.View.ElementOptionsPanel.Editor.AbstractCollectionEditor.extend({
    availableValidators: null,
    availableCollectionElementsBinding: 'availableValidators',
    templateName: 'ElementOptionsPanel-ValidatorEditor',
    prompt: 'Select a validator to add',
    propertyPath: 'validators'
  });

  TYPO3.FormBuilder.View.ElementOptionsPanel.Editor.ValidatorEditor.DefaultValidatorEditor = Ember.View.extend({
    classNames: ['typo3-formbuilder-validator-editor'],
    templateName: 'Validator-Default',
    required: false,
    collection: null,
    elementIndex: null,
    currentCollectionElement: (function() {
      return this.get('collection').get(this.get('elementIndex'));
    }).property('collection', 'elementIndex').cacheable(),
    valueChanged: Ember.K,
    updateCollectionEditorViews: Ember.K,
    remove: function() {
      this.get('collection').removeAt(this.get('elementIndex'));
      this.valueChanged();
      return this.updateCollectionEditorViews();
    },
    notRequired: (function() {
      return !this.get('required');
    }).property('required').cacheable()
  });

  TYPO3.FormBuilder.View.ElementOptionsPanel.Editor.ValidatorEditor.MinimumMaximumValidatorEditor = TYPO3.FormBuilder.View.ElementOptionsPanel.Editor.ValidatorEditor.DefaultValidatorEditor.extend({
    templateName: 'Validator-MinimumMaximumEditor',
    pathToMinimumOption: 'currentCollectionElement.options.minimum',
    pathToMaximumOption: 'currentCollectionElement.options.maximum',
    minimum: (function(k, v) {
      if (v !== void 0) {
        this.setPath(this.get('pathToMinimumOption'), v);
        this.valueChanged();
        return v;
      } else {
        return this.getPath(this.get('pathToMinimumOption'));
      }
    }).property('pathToMinimumOption').cacheable(),
    maximum: (function(k, v) {
      if (v !== void 0) {
        this.setPath(this.get('pathToMaximumOption'), v);
        this.valueChanged();
        return v;
      } else {
        return this.getPath(this.get('pathToMaximumOption'));
      }
    }).property('pathToMaximumOption').cacheable()
  });

  TYPO3.FormBuilder.View.ElementOptionsPanel.Editor.ValidatorEditor.SimpleValueValidatorEditor = TYPO3.FormBuilder.View.ElementOptionsPanel.Editor.ValidatorEditor.DefaultValidatorEditor.extend({
    templateName: 'Validator-SimpleValueEditor',
    pathToEditedValue: 'currentCollectionElement.options.TODO',
    fieldLabel: Ember.required(),
    value: (function(k, v) {
      if (v !== void 0) {
        this.setPath(this.get('pathToEditedValue'), v);
        this.valueChanged();
        return v;
      } else {
        return this.getPath(this.get('pathToEditedValue'));
      }
    }).property('pathToEditedValue').cacheable()
  });

  TYPO3.FormBuilder.View.ElementOptionsPanel.Editor.FinisherEditor = TYPO3.FormBuilder.View.ElementOptionsPanel.Editor.AbstractCollectionEditor.extend({
    availableFinishers: null,
    availableCollectionElementsBinding: 'availableFinishers',
    templateName: 'ElementOptionsPanel-FinisherEditor',
    prompt: 'Select a finisher to add',
    propertyPath: 'finishers'
  });

  TYPO3.FormBuilder.View.ElementOptionsPanel.Editor.FinisherEditor.EmailFinisherEditor = TYPO3.FormBuilder.View.ElementOptionsPanel.Editor.ValidatorEditor.DefaultValidatorEditor.extend({
    templateName: 'Finisher-EmailEditor',
    availableFormats: null,
    format: (function(k, v) {
      var chosenFormatKey, format, _k, _len3, _ref7;
      if (arguments.length >= 2) {
        this.setPath('currentCollectionElement.options.format', v.key);
      }
      chosenFormatKey = this.getPath('currentCollectionElement.options.format');
      _ref7 = this.get('availableFormats');
      for (_k = 0, _len3 = _ref7.length; _k < _len3; _k++) {
        format = _ref7[_k];
        if (format.key === chosenFormatKey) return format;
      }
      return null;
    }).property('availableFormats').cacheable()
  });

}).call(this);
