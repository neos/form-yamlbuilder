(function() {
  var TYPO3, convertToSimpleObject, cssFile, _i, _len, _ref,
    __hasProp = Object.prototype.hasOwnProperty;

  TYPO3 = window.TYPO3 || {};

  window.TYPO3 = TYPO3;

  TYPO3.FormBuilder = Ember.Application.create({
    rootElement: 'body'
  });

  TYPO3.FormBuilder.Configuration = window.FORMBUILDER_CONFIGURATION;

  if (TYPO3.FormBuilder.Configuration.cssFiles) {
    _ref = TYPO3.FormBuilder.Configuration.cssFiles;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      cssFile = _ref[_i];
      $('head').append($('<link rel="stylesheet" />').attr('href', cssFile));
    }
  }

  window.setTimeout((function() {
    return TYPO3.FormBuilder.Model.Form.set('formDefinition', TYPO3.FormBuilder.Model.Renderable.create({
      identifier: 'myForm',
      renderables: [
        {
          type: 'TYPO3.Form:Page',
          identifier: 'myPage',
          label: 'My Page 1',
          renderables: [
            {
              identifier: 'foobarbaz',
              type: 'TYPO3.Form:Textfield',
              label: 'My Label'
            }, {
              identifier: 'foobarbaz2',
              type: 'TYPO3.Form:Textfield',
              label: 'My Label'
            }, {
              identifier: 'gender',
              type: 'TYPO3.Form:Radiobuttons',
              label: 'Gender',
              properties: {
                options: [
                  {
                    _key: 'm',
                    _value: 'Male'
                  }, {
                    _key: 'f',
                    _value: 'Female'
                  }
                ]
              }
            }
          ]
        }, {
          type: 'TYPO3.Form:Page',
          identifier: 'myPage2',
          label: ''
        }
      ]
    }));
  }), 2000);

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

  TYPO3.FormBuilder.Model = {};

  TYPO3.FormBuilder.Model.Form = Ember.Object.create({
    formDefinition: null,
    currentlySelectedRenderable: null
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
        if (!currentObject[firstPartOfPath]) currentObject[firstPartOfPath] = {};
        currentObject = currentObject[firstPartOfPath];
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
      var i, _ref2, _results;
      _results = [];
      for (i = startIndex, _ref2 = startIndex + removeCount; startIndex <= _ref2 ? i < _ref2 : i > _ref2; startIndex <= _ref2 ? i++ : i--) {
        _results.push(subArray.objectAt(i).set('parentRenderable', null));
      }
      return _results;
    },
    arrayDidChange: function(subArray, startIndex, removeCount, addCount) {
      var i, _ref2;
      for (i = startIndex, _ref2 = startIndex + addCount; startIndex <= _ref2 ? i < _ref2 : i > _ref2; startIndex <= _ref2 ? i++ : i--) {
        subArray.objectAt(i).set('parentRenderable', this);
      }
      this.set('__nestedPropertyChange', this.get('__nestedPropertyChange') + 1);
      if (this.parentRenderable) {
        return this.parentRenderable.somePropertyChanged(this.parentRenderable, "renderables");
      }
    },
    _path: (function() {
      if (this.parentRenderable) {
        return "" + (this.parentRenderable.get('_path')) + ".renderables." + (this.parentRenderable.get('renderables').indexOf(this));
      } else {
        return '';
      }
    }).property()
  });

  TYPO3.FormBuilder.Model.Renderable.reopenClass({
    create: function(obj) {
      var childRenderable, childRenderables, k, renderable, v, _j, _len2;
      childRenderables = obj.renderables;
      delete obj.renderables;
      renderable = Ember.Object.create.call(TYPO3.FormBuilder.Model.Renderable, obj);
      for (k in obj) {
        v = obj[k];
        renderable.addObserver(k, renderable, 'somePropertyChanged');
      }
      if (childRenderables) {
        for (_j = 0, _len2 = childRenderables.length; _j < _len2; _j++) {
          childRenderable = childRenderables[_j];
          renderable.get('renderables').pushObject(TYPO3.FormBuilder.Model.Renderable.create(childRenderable));
        }
      }
      return renderable;
    }
  });

  TYPO3.FormBuilder.Model.FormElementType = Ember.Object.extend({
    _isCompositeRenderable: false
  });

  TYPO3.FormBuilder.Model.FormElementTypes = Ember.Object.create({
    allTypeNames: [],
    init: function() {
      var typeConfiguration, typeName, _ref2, _ref3, _results;
      if (((_ref2 = TYPO3.FormBuilder.Configuration) != null ? _ref2.formElementTypes : void 0) == null) {
        return;
      }
      _ref3 = TYPO3.FormBuilder.Configuration.formElementTypes;
      _results = [];
      for (typeName in _ref3) {
        typeConfiguration = _ref3[typeName];
        this.allTypeNames.push(typeName);
        _results.push(this.set(typeName, TYPO3.FormBuilder.Model.FormElementType.create(typeConfiguration)));
      }
      return _results;
    }
  });

  TYPO3.FormBuilder.Model.FormElementGroups = Ember.Object.create({
    allGroupNames: [],
    init: function() {
      var groupConfiguration, groupName, _ref2, _ref3, _results;
      if (((_ref2 = TYPO3.FormBuilder.Configuration) != null ? _ref2.formElementGroups : void 0) == null) {
        return;
      }
      _ref3 = TYPO3.FormBuilder.Configuration.formElementGroups;
      _results = [];
      for (groupName in _ref3) {
        groupConfiguration = _ref3[groupName];
        this.allGroupNames.push(groupName);
        _results.push(this.set(groupName, Ember.Object.create(groupConfiguration)));
      }
      return _results;
    }
  });

  TYPO3.FormBuilder.View = {};

  TYPO3.FormBuilder.View.FormPageView = Ember.View.extend({
    formPagesBinding: 'TYPO3.FormBuilder.Model.Form.formDefinition.renderables',
    currentPageIndex: 0,
    currentAjaxRequest: null,
    page: Ember.computed(function() {
      var _ref2;
      return (_ref2 = this.get('formPages')) != null ? _ref2.get(this.get('currentPageIndex')) : void 0;
    }).property('formPages', 'currentPageIndex').cacheable(),
    renderPageIfPageObjectChanges: (function() {
      var _ref2,
        _this = this;
      if (!((_ref2 = TYPO3.FormBuilder.Model.Form.get('formDefinition')) != null ? _ref2.get('identifier') : void 0)) {
        return;
      }
      if (this.currentAjaxRequest) this.currentAjaxRequest.abort();
      if (this.timeout) window.clearTimeout(this.timeout);
      return this.timeout = window.setTimeout(function() {
        var formDefinition;
        formDefinition = TYPO3.FormBuilder.Utility.convertToSimpleObject(TYPO3.FormBuilder.Model.Form.get('formDefinition'));
        return _this.currentAjaxRequest = $.post(TYPO3.FormBuilder.Configuration.endpoints.formPageRenderer, {
          formDefinition: formDefinition
        }, function(data, textStatus, jqXHR) {
          if (_this.currentAjaxRequest !== jqXHR) return;
          _this.$().html(data);
          return _this.postProcessRenderedPage();
        });
      }, 300);
    }).observes('page', 'page.__nestedPropertyChange'),
    postProcessRenderedPage: function() {
      var _this = this;
      this.$().find('[data-element]').parent().addClass('typo3-form-sortable').sortable({
        revert: 'true',
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
          if (!nextElement && !previousElement) {
            throw 'Next Element or Previous Element need to be set. Should not happen...';
          }
          if (nextElement) {
            referenceElementIndex = nextElement.getPath('parentRenderable.renderables').indexOf(nextElement);
            return nextElement.getPath('parentRenderable.renderables').insertAt(referenceElementIndex, movedRenderable);
          } else if (previousElement) {
            referenceElementIndex = previousElement.getPath('parentRenderable.renderables').indexOf(previousElement);
            return previousElement.getPath('parentRenderable.renderables').insertAt(referenceElementIndex + 1, movedRenderable);
          }
        }
      });
      return this.onCurrentElementChanges();
    },
    onCurrentElementChanges: (function() {
      var identifierPath, renderable;
      renderable = TYPO3.FormBuilder.Model.Form.get('currentlySelectedRenderable');
      if (!renderable) return;
      this.$().find('.formbuilder-form-element-selected').removeClass('formbuilder-form-element-selected');
      identifierPath = renderable.identifier;
      while (renderable = renderable.parentRenderable) {
        identifierPath = renderable.identifier + '/' + identifierPath;
      }
      return this.$().find('[data-element="' + identifierPath + '"]').addClass('formbuilder-form-element-selected');
    }).observes('TYPO3.FormBuilder.Model.Form.currentlySelectedRenderable'),
    findRenderableForPath: function(path) {
      var currentRenderable, expandedPathToClickedElement, pathPart, renderable, _j, _k, _len2, _len3, _ref2;
      expandedPathToClickedElement = path.split('/');
      expandedPathToClickedElement.shift();
      expandedPathToClickedElement.shift();
      currentRenderable = this.get('page');
      for (_j = 0, _len2 = expandedPathToClickedElement.length; _j < _len2; _j++) {
        pathPart = expandedPathToClickedElement[_j];
        _ref2 = currentRenderable.get('renderables');
        for (_k = 0, _len3 = _ref2.length; _k < _len3; _k++) {
          renderable = _ref2[_k];
          if (renderable.identifier === pathPart) {
            currentRenderable = renderable;
            break;
          }
        }
      }
      return currentRenderable;
    },
    click: function(e) {
      var pathToClickedElement;
      pathToClickedElement = $(e.target).closest('[data-element]').attr('data-element');
      if (!pathToClickedElement) return;
      return TYPO3.FormBuilder.Model.Form.set('currentlySelectedRenderable', this.findRenderableForPath(pathToClickedElement));
    }
  });

  TYPO3.FormBuilder.View.ContainerView = Ember.ContainerView.extend({
    instanciatedViews: null,
    onInstanciatedViewsChange: (function() {
      var view, _j, _len2, _ref2;
      this.removeAllChildren();
      _ref2 = this.get('instanciatedViews');
      for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
        view = _ref2[_j];
        this.get('childViews').push(view);
      }
      return this.rerender();
    }).observes('instanciatedViews')
  });

  TYPO3.FormBuilder.View.Select = Ember.Select.extend({
    attributeBindings: ['disabled']
  });

  TYPO3.FormBuilder.View.AvailableFormElementsView = Ember.View.extend({
    classNames: ['availableFormElements'],
    allFormElementTypesBinding: 'TYPO3.FormBuilder.Model.FormElementTypes.allTypeNames',
    formElementsGrouped: (function() {
      var formElementType, formElementTypeName, formElementsByGroup, formGroup, formGroupName, formGroups, _j, _k, _len2, _len3, _ref2, _ref3, _ref4, _ref5;
      formElementsByGroup = {};
      _ref2 = this.get('allFormElementTypes');
      for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
        formElementTypeName = _ref2[_j];
        formElementType = TYPO3.FormBuilder.Model.FormElementTypes.get(formElementTypeName);
        if (((_ref3 = formElementType.formBuilder) != null ? _ref3.group : void 0) == null) {
          continue;
        }
        if (!formElementsByGroup[formElementType.formBuilder.group]) {
          formElementsByGroup[formElementType.formBuilder.group] = [];
        }
        formElementType.set('key', formElementTypeName);
        formElementsByGroup[formElementType.formBuilder.group].push(formElementType);
      }
      formGroups = [];
      _ref4 = TYPO3.FormBuilder.Model.FormElementGroups.get('allGroupNames');
      for (_k = 0, _len3 = _ref4.length; _k < _len3; _k++) {
        formGroupName = _ref4[_k];
        formGroup = TYPO3.FormBuilder.Model.FormElementGroups.get(formGroupName);
        formGroup.set('key', formGroupName);
        if ((_ref5 = formElementsByGroup[formGroupName]) != null) {
          _ref5.sort(function(a, b) {
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
    }).property('allFormElementTypes').cacheable(),
    templateName: 'AvailableFormElements'
  });

  TYPO3.FormBuilder.View.AvailableFormElementsElement = Ember.View.extend({
    tagName: 'li',
    formElementType: null,
    currentlySelectedElementBinding: 'TYPO3.FormBuilder.Model.Form.currentlySelectedRenderable',
    didInsertElement: function() {
      this.$().html(this.getPath('formElementType.formBuilder.label'));
      return this.$().attr('title', this.getPath('formElementType.key'));
    },
    click: function() {
      var el, indexInParent, newRenderable, parentRenderablesArray;
      el = this.get('currentlySelectedElement');
      if (!el) return;
      parentRenderablesArray = el.getPath('parentRenderable.renderables');
      indexInParent = parentRenderablesArray.indexOf(el);
      newRenderable = TYPO3.FormBuilder.Model.Renderable.create({
        type: this.formElementType.get('key'),
        label: '',
        identifier: Ember.generateGuid(null, 'formElement')
      });
      parentRenderablesArray.replace(indexInParent + 1, 0, [newRenderable]);
      return this.set('currentlySelectedElement', newRenderable);
    }
  });

  TYPO3.FormBuilder.View.FormTree = Ember.View.extend({
    formDefinitionBinding: 'TYPO3.FormBuilder.Model.Form.formDefinition',
    didInsertElement: function() {
      this.$().dynatree({
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
            targetNodeIsCompositeRenderable = TYPO3.FormBuilder.Model.FormElementTypes.get(targetNode.data.formRenderable.get('type')).getPath('formBuilder.__isCompositeRenderable');
            if (sourceNode.getLevel() === 1) {
              if (targetNode.getLevel() === 1) {
                return ['before', 'after'];
              } else {
                return false;
              }
            } else {
              if (targetNode.getLevel() === 1) {
                return ['over'];
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
              return targetRenderable.get('renderables').pushObject(sourceRenderable);
            } else {
              indexOfTargetRenderable = targetRenderable.getPath('parentRenderable.renderables').indexOf(targetRenderable);
              if (hitMode === 'before') {
                return targetRenderable.getPath('parentRenderable.renderables').insertAt(indexOfTargetRenderable, sourceRenderable);
              } else {
                return targetRenderable.getPath('parentRenderable.renderables').insertAt(indexOfTargetRenderable + 1, sourceRenderable);
              }
            }
          }
        }
      });
      return this.updateTreeStateFromModel(this.$().dynatree('getRoot'), this.getPath('formDefinition.renderables'));
    },
    updateTree: (function() {
      var activeNodePath, expandedNodePath, expandedNodePaths, _base, _j, _len2, _ref2, _ref3;
      if (!this.$().dynatree('getTree').visit) return;
      expandedNodePaths = [];
      this.$().dynatree('getTree').visit(function(node) {
        if (node.isExpanded()) return expandedNodePaths.push(node.data.key);
      });
      activeNodePath = (_ref2 = this.$().dynatree('getActiveNode')) != null ? _ref2.data.key : void 0;
      if (typeof (_base = this.$().dynatree('getRoot')).removeChildren === "function") {
        _base.removeChildren();
      }
      this.updateTreeStateFromModel(this.$().dynatree('getRoot'), this.getPath('formDefinition.renderables'));
      for (_j = 0, _len2 = expandedNodePaths.length; _j < _len2; _j++) {
        expandedNodePath = expandedNodePaths[_j];
        this.$().dynatree('getTree').getNodeByKey(expandedNodePath).expand(true);
      }
      return (_ref3 = this.$().dynatree('getTree').getNodeByKey(activeNodePath)) != null ? _ref3.activate(true) : void 0;
    }).observes('formDefinition.__nestedPropertyChange'),
    updateTreeStateFromModel: function(dynaTreeParentNode, currentListOfSubRenderables) {
      var newNode, subRenderable, _j, _len2, _results;
      if (!currentListOfSubRenderables) return;
      _results = [];
      for (_j = 0, _len2 = currentListOfSubRenderables.length; _j < _len2; _j++) {
        subRenderable = currentListOfSubRenderables[_j];
        newNode = dynaTreeParentNode.addChild({
          key: subRenderable.get('_path'),
          title: subRenderable.label ? subRenderable.label : subRenderable.identifier,
          formRenderable: subRenderable
        });
        _results.push(this.updateTreeStateFromModel(newNode, subRenderable.getPath('renderables')));
      }
      return _results;
    },
    updateCurrentlySelectedNode: (function() {
      var activeNodePath, _base, _ref2;
      activeNodePath = TYPO3.FormBuilder.Model.Form.getPath('currentlySelectedRenderable._path');
      return typeof (_base = this.$().dynatree('getTree')).getNodeByKey === "function" ? (_ref2 = _base.getNodeByKey(activeNodePath)) != null ? _ref2.activate(true) : void 0 : void 0;
    }).observes('TYPO3.FormBuilder.Model.Form.currentlySelectedRenderable')
  });

  TYPO3.FormBuilder.View.FormElementInspector = Ember.ContainerView.extend({
    formElement: null,
    orderedFormFieldEditors: (function() {
      var formFieldEditors, k, orderedFormFieldEditors, v;
      formFieldEditors = $.extend({}, this.getPath('formElement.typeDefinition.formBuilder.formFieldEditors'));
      orderedFormFieldEditors = (function() {
        var _results;
        _results = [];
        for (k in formFieldEditors) {
          v = formFieldEditors[k];
          v['key'] = k;
          _results.push(v);
        }
        return _results;
      })();
      orderedFormFieldEditors.sort(function(a, b) {
        return a.sorting - b.sorting;
      });
      return orderedFormFieldEditors;
    }).property('formElement.typeDefinition').cacheable(),
    onFormElementChange: (function() {
      var formFieldEditor, subView, subViewClass, subViewOptions, _j, _len2, _ref2;
      this.removeAllChildren();
      if (!this.formElement) return;
      _ref2 = this.get('orderedFormFieldEditors');
      for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
        formFieldEditor = _ref2[_j];
        subViewClass = Ember.getPath(formFieldEditor.viewName);
        if (!subViewClass) {
          throw "Editor class '" + formFieldEditor.viewName + "' not found";
        }
        subViewOptions = $.extend({}, formFieldEditor, {
          formElement: this.formElement
        });
        subView = subViewClass.create(subViewOptions);
        this.get('childViews').push(subView);
      }
      return this.rerender();
    }).observes('formElement')
  });

  TYPO3.FormBuilder.View.Editor = {};

  TYPO3.FormBuilder.View.Editor.AbstractEditor = Ember.View.extend({
    classNames: ['form-editor'],
    formElement: null
  });

  TYPO3.FormBuilder.View.Editor.AbstractPropertyEditor = TYPO3.FormBuilder.View.Editor.AbstractEditor.extend({
    /* PUBLIC API
    */
    propertyPath: null,
    /* API FOR SUBCLASSES
    */
    defaultValue: '',
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
    }).property('propertyPath', 'formElement').cacheable(),
    valueChanged: function() {
      var _base;
      return typeof (_base = this.get('formElement')).somePropertyChanged === "function" ? _base.somePropertyChanged(this.formElement, this.get('propertyPath')) : void 0;
    }
  });

  TYPO3.FormBuilder.View.Editor.TextOutput = TYPO3.FormBuilder.View.Editor.AbstractEditor.extend({});

  TYPO3.FormBuilder.View.Editor.LabelEditor = TYPO3.FormBuilder.View.Editor.AbstractEditor.extend({
    templateName: 'LabelEditor',
    label: (function(k, v) {
      if (v !== void 0) {
        return this.setPath('formElement.label', v);
      } else {
        return this.getPath('formElement.label');
      }
    }).property('formElement').cacheable(),
    identifier: (function(k, v) {
      if (v !== void 0) {
        return this.setPath('formElement.identifier', v);
      } else {
        return this.getPath('formElement.identifier');
      }
    }).property('formElement').cacheable()
  });

  TYPO3.FormBuilder.View.Editor.TextEditor = TYPO3.FormBuilder.View.Editor.AbstractPropertyEditor.extend({
    /* PUBLIC API
    */
    label: null,
    onValueChange: (function() {
      return this.valueChanged();
    }).observes('value'),
    /* PRIVATE
    */
    templateName: 'TextEditor'
  });

  TYPO3.FormBuilder.View.Editor.PropertyGrid = TYPO3.FormBuilder.View.Editor.AbstractPropertyEditor.extend({
    /* PUBLIC API
    */
    columns: null,
    isSortable: false,
    enableAddRow: false,
    /* PRIVATE
    */
    templateName: 'PropertyGridEditor',
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
      var column, columns, _j, _len2, _ref2;
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
      _ref2 = this.get('columns');
      for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
        column = _ref2[_j];
        column = $.extend({}, column);
        column.id = column.field;
        column.editor = Ember.getPath(column.editor);
        columns.push(column);
      }
      return columns;
    }).property('columns', 'isSortable').cacheable(),
    grid: null,
    init: function() {
      this.classNames.push('PropertyGrid');
      return this._super();
    },
    didInsertElement: function() {
      var moveRowsPlugin,
        _this = this;
      this.grid = new Slick.Grid(this.$().find('.grid'), this.get('value'), this.get('columnDefinition'), this.get('options'));
      this.$().find('.slick-viewport').css('overflow-x', 'hidden');
      this.$().find('.slick-viewport').css('overflow-y', 'hidden');
      this.grid.setSelectionModel(new Slick.RowSelectionModel());
      this.grid.onCellChange.subscribe(function(e, args) {
        _this.get('value').replace(args.row, 1, args.item);
        return _this.valueChanged();
      });
      this.grid.onAddNewRow.subscribe(function(e, args) {
        var columnDefinition, newItem, _j, _len2, _ref2;
        _this.grid.invalidateRow(_this.get('value').length);
        newItem = {};
        _ref2 = _this.columns;
        for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
          columnDefinition = _ref2[_j];
          newItem[columnDefinition.field] = '';
        }
        $.extend(newItem, args.item);
        _this.get('value').push(newItem);
        _this.grid.updateRowCount();
        _this.grid.render();
        return _this.valueChanged();
      });
      moveRowsPlugin = new Slick.RowMoveManager();
      this.grid.registerPlugin(moveRowsPlugin);
      moveRowsPlugin.onBeforeMoveRows.subscribe(function(e, data) {
        var i, _ref2;
        for (i = 0, _ref2 = data.rows.length; 0 <= _ref2 ? i < _ref2 : i > _ref2; 0 <= _ref2 ? i++ : i--) {
          if (data.rows[i] === data.insertBefore || data.rows[i] === data.insertBefore - 1) {
            e.stopPropagation();
            return false;
          }
        }
        return true;
      });
      return moveRowsPlugin.onMoveRows.subscribe(function(e, args) {
        var arrayRowToBeMoved, movedRowIndex;
        movedRowIndex = args.rows[0];
        arrayRowToBeMoved = _this.get('value').objectAt(movedRowIndex);
        _this.get('value').removeAt(movedRowIndex, 1);
        if (movedRowIndex < args.insertBefore) args.insertBefore--;
        _this.get('value').insertAt(args.insertBefore, arrayRowToBeMoved);
        _this.valueChanged();
        _this.grid.invalidateAllRows();
        return _this.grid.render();
      });
    }
  });

  TYPO3.FormBuilder.View.Editor.RequiredValidatorEditor = TYPO3.FormBuilder.View.Editor.AbstractPropertyEditor.extend({
    /* PUBLIC API
    */
    /* PRIVATE
    */
    templateName: 'RequiredValidatorEditor',
    propertyPath: 'validators',
    defaultValue: (function() {
      return [];
    }).property().cacheable(),
    isRequiredValidatorConfigured: (function(k, v) {
      var a, notEmptyValidatorClassName, val;
      notEmptyValidatorClassName = 'TYPO3\\FLOW3\\Validation\\Validator\\NotEmptyValidator';
      if (v !== void 0) {
        a = this.get('value').filter(function(validatorConfiguration) {
          return validatorConfiguration.name !== notEmptyValidatorClassName;
        });
        this.set('value', a);
        if (v === true) {
          this.get('value').push({
            name: notEmptyValidatorClassName
          });
        }
        this.valueChanged();
        return v;
      } else {
        val = !!this.get('value').some(function(validatorConfiguration) {
          return validatorConfiguration.name === notEmptyValidatorClassName;
        });
        return val;
      }
    }).property('value').cacheable()
  });

  TYPO3.FormBuilder.View.Editor.ValidatorEditor = TYPO3.FormBuilder.View.Editor.AbstractPropertyEditor.extend({
    availableValidators: null,
    templateName: 'ValidatorEditor',
    propertyPath: 'validators',
    defaultValue: (function() {
      return [];
    }).property().cacheable(),
    init: function() {
      this._super();
      this.validatorEditorViews = [];
      return this.updateValidatorEditorViews();
    },
    sortedAvailableValidators: (function() {
      var key, validatorTemplate, validatorsArray, _ref2;
      validatorsArray = [];
      _ref2 = this.get('availableValidators');
      for (key in _ref2) {
        validatorTemplate = _ref2[key];
        if (this.isValidatorTemplateFoundInValidatorList(validatorTemplate)) {
          continue;
        }
        validatorsArray.push($.extend({
          key: key
        }, validatorTemplate));
      }
      validatorsArray.sort(function(a, b) {
        return a.sorting - b.sorting;
      });
      return validatorsArray;
    }).property('availableValidators', 'formElement.__nestedPropertyChange').cacheable(),
    noValidatorsAvailable: (function() {
      return this.get('sortedAvailableValidators').length === 0;
    }).property('sortedAvailableValidators').cacheable(),
    addValidatorSelection: null,
    addValidator: (function() {
      var validatorToBeAdded;
      validatorToBeAdded = this.get('addValidatorSelection');
      if (!validatorToBeAdded) return;
      this.get('value').push({
        name: validatorToBeAdded.name,
        options: validatorToBeAdded.options
      });
      this.valueChanged();
      this.updateValidatorEditorViews();
      return this.set('addValidatorSelection', null);
    }).observes('addValidatorSelection'),
    validatorEditorViews: null,
    updateValidatorEditorViews: (function() {
      var availableValidators, i, key, validator, validatorEditor, validatorEditorOptions, validatorTemplate, validatorViews, validators, _len2,
        _this = this;
      this.addRequiredValidatorsIfNeededToValidatorList();
      validators = this.get('value');
      availableValidators = this.get('availableValidators');
      validatorViews = [];
      for (i = 0, _len2 = validators.length; i < _len2; i++) {
        validator = validators[i];
        for (key in availableValidators) {
          validatorTemplate = availableValidators[key];
          if (validatorTemplate.name === validator.name) {
            validatorEditor = Ember.getPath(validatorTemplate.viewName || 'TYPO3.FormBuilder.View.Editor.ValidatorEditor.DefaultValidatorEditor');
            if (!validatorEditor) {
              throw "Validator Editor class '" + validatorTemplate.viewName + "' not found";
            }
            validatorEditorOptions = $.extend({
              validatorIndex: i,
              valueChanged: function() {
                return _this.valueChanged();
              },
              updateValidatorEditorViews: function() {
                return _this.updateValidatorEditorViews();
              },
              validators: this.get('value')
            }, validatorTemplate);
            validatorViews.push(validatorEditor.create(validatorEditorOptions));
            break;
          }
        }
      }
      return this.set('validatorEditorViews', validatorViews);
    }).observes('value'),
    addRequiredValidatorsIfNeededToValidatorList: function() {
      var availableValidators, key, requiredAndMissingValidators, validatorTemplate, validatorTemplateName, validators, _j, _len2, _results;
      validators = this.get('value');
      availableValidators = this.get('availableValidators');
      requiredAndMissingValidators = [];
      for (key in availableValidators) {
        validatorTemplate = availableValidators[key];
        if (!validatorTemplate.required) continue;
        if (!this.isValidatorTemplateFoundInValidatorList(validatorTemplate)) {
          requiredAndMissingValidators.push(key);
        }
      }
      _results = [];
      for (_j = 0, _len2 = requiredAndMissingValidators.length; _j < _len2; _j++) {
        validatorTemplateName = requiredAndMissingValidators[_j];
        _results.push(validators.push({
          name: availableValidators[validatorTemplateName].name,
          options: $.extend({}, availableValidators[validatorTemplateName].options)
        }));
      }
      return _results;
    },
    isValidatorTemplateFoundInValidatorList: function(validatorTemplate) {
      var validator, validators, _j, _len2;
      validators = this.get('value');
      for (_j = 0, _len2 = validators.length; _j < _len2; _j++) {
        validator = validators[_j];
        if (validatorTemplate.name === validator.name) return true;
      }
      return false;
    }
  });

  TYPO3.FormBuilder.View.Editor.ValidatorEditor.DefaultValidatorEditor = Ember.View.extend({
    classNames: ['formbuilder-validator-editor'],
    templateName: 'ValidatorEditor-Default',
    required: false,
    validators: null,
    validatorIndex: null,
    validator: (function() {
      return this.get('validators').get(this.get('validatorIndex'));
    }).property('validators', 'validatorIndex'),
    valueChanged: Ember.K,
    notRequired: (function() {
      return !this.get('required');
    }).property('required').cacheable(),
    remove: function() {
      this.get('validators').removeAt(this.get('validatorIndex'));
      this.valueChanged();
      return this.updateValidatorEditorViews();
    }
  });

  TYPO3.FormBuilder.View.Editor.ValidatorEditor.MinimumMaximumValidatorEditor = TYPO3.FormBuilder.View.Editor.ValidatorEditor.DefaultValidatorEditor.extend({
    templateName: 'ValidatorEditor-MinimumMaximum',
    pathToMinimumOption: 'validator.options.minimum',
    pathToMaximumOption: 'validator.options.maximum',
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

}).call(this);
