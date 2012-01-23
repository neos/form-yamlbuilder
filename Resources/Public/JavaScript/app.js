(function() {
  var TYPO3, convertToSimpleObject,
    __hasProp = Object.prototype.hasOwnProperty;

  TYPO3 = window.TYPO3 || {};

  window.TYPO3 = TYPO3;

  TYPO3.FormBuilder = Ember.Application.create({
    rootElement: 'body'
  });

  TYPO3.FormBuilder.Configuration = window.FORMBUILDER_CONFIGURATION;

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

  TYPO3.FormBuilder.Model.Renderable = Ember.Object.extend({
    parentRenderable: null,
    renderables: null,
    __nestedPropertyChange: 0,
    init: function() {
      this.renderables = [];
      return this.renderables.addArrayObserver(this);
    },
    somePropertyChanged: function(theInstance, propertyName) {
      this.set('__nestedPropertyChange', this.get('__nestedPropertyChange') + 1);
      if (this.parentRenderable) {
        return this.parentRenderable.somePropertyChanged(this.parentRenderable, "renderables." + (this.parentRenderable.get('renderables').indexOf(this)) + "." + propertyName);
      }
    },
    arrayWillChange: function(subArray, startIndex, removeCount, addCount) {
      var i, _ref, _results;
      _results = [];
      for (i = startIndex, _ref = startIndex + removeCount; startIndex <= _ref ? i < _ref : i > _ref; startIndex <= _ref ? i++ : i--) {
        _results.push(subArray.objectAt(i).set('parentRenderable', null));
      }
      return _results;
    },
    arrayDidChange: function(subArray, startIndex, removeCount, addCount) {
      var i, _ref;
      for (i = startIndex, _ref = startIndex + addCount; startIndex <= _ref ? i < _ref : i > _ref; startIndex <= _ref ? i++ : i--) {
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
      var childRenderable, childRenderables, k, renderable, v, _i, _len;
      childRenderables = obj.renderables;
      delete obj.renderables;
      renderable = Ember.Object.create.call(TYPO3.FormBuilder.Model.Renderable, obj);
      for (k in obj) {
        v = obj[k];
        renderable.addObserver(k, renderable, 'somePropertyChanged');
      }
      if (childRenderables) {
        for (_i = 0, _len = childRenderables.length; _i < _len; _i++) {
          childRenderable = childRenderables[_i];
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
      var typeConfiguration, typeName, _ref, _results;
      _ref = TYPO3.FormBuilder.Configuration.formElementTypes;
      _results = [];
      for (typeName in _ref) {
        typeConfiguration = _ref[typeName];
        this.allTypeNames.push(typeName);
        _results.push(this.set(typeName, TYPO3.FormBuilder.Model.FormElementType.create(typeConfiguration)));
      }
      return _results;
    }
  });

  TYPO3.FormBuilder.Model.FormElementGroups = Ember.Object.create({
    allGroupNames: [],
    init: function() {
      var groupConfiguration, groupName, _ref, _results;
      _ref = TYPO3.FormBuilder.Configuration.formElementGroups;
      _results = [];
      for (groupName in _ref) {
        groupConfiguration = _ref[groupName];
        this.allGroupNames.push(groupName);
        _results.push(this.set(groupName, Ember.Object.create(groupConfiguration)));
      }
      return _results;
    }
  });

  TYPO3.FormBuilder.Model.Form = Ember.Object.create({
    formDefinition: null,
    currentlySelectedRenderable: null
  });

  TYPO3.FormBuilder.View = {};

  TYPO3.FormBuilder.View.AvailableFormElementsView = Ember.View.extend({
    allFormElementTypesBinding: 'TYPO3.FormBuilder.Model.FormElementTypes.allTypeNames',
    formElementsGrouped: (function() {
      var formElementType, formElementTypeName, formElementsByGroup, formGroup, formGroupName, formGroups, _i, _j, _len, _len2, _ref, _ref2;
      console.log("ASDF");
      formElementsByGroup = {};
      _ref = this.get('allFormElementTypes');
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        formElementTypeName = _ref[_i];
        formElementType = TYPO3.FormBuilder.Model.FormElementTypes.get(formElementTypeName);
        if (!formElementsByGroup[formElementType.group]) {
          formElementsByGroup[formElementType.group] = [];
        }
        formElementType.set('key', formElementTypeName);
        formElementsByGroup[formElementType.group].push(formElementType);
      }
      formGroups = [];
      _ref2 = TYPO3.FormBuilder.Model.FormElementGroups.get('allGroupNames');
      for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
        formGroupName = _ref2[_j];
        formGroup = TYPO3.FormBuilder.Model.FormElementGroups.get(formGroupName);
        formGroup.set('key', formGroupName);
        formElementsByGroup[formGroupName].sort(function(a, b) {
          return a.sorting - b.sorting;
        });
        formGroup.set('elements', formElementsByGroup[formGroupName]);
        formGroups.push(formGroup);
      }
      formGroups.sort(function(a, b) {
        return a.sorting - b.sorting;
      });
      console.log(formGroups);
      return formGroups;
    }).property('allFormElementTypes').cacheable(),
    templateName: 'AvailableFormElements'
  });

  TYPO3.FormBuilder.View.AvailableFormElementsElement = Ember.View.extend({
    tagName: 'li',
    formElementType: null,
    currentlySelectedElementBinding: 'TYPO3.FormBuilder.Model.Form.currentlySelectedRenderable',
    didInsertElement: function() {
      return this.$().html(this.getPath('formElementType.label'));
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
        identifier: 'ASDF'
      });
      return parentRenderablesArray.replace(indexInParent + 1, 0, [newRenderable]);
    }
  });

  TYPO3.FormBuilder.View.FormStructure = Ember.View.extend({
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
            targetNodeIsCompositeRenderable = TYPO3.FormBuilder.Model.FormElementTypes.get("" + (targetNode.data.formRenderable.get('type')) + "._isCompositeRenderable");
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
      var activeNodePath, expandedNodePath, expandedNodePaths, _base, _i, _len, _ref, _ref2;
      if (!this.$().dynatree('getTree').visit) return;
      expandedNodePaths = [];
      this.$().dynatree('getTree').visit(function(node) {
        if (node.isExpanded()) return expandedNodePaths.push(node.data.key);
      });
      activeNodePath = (_ref = this.$().dynatree('getActiveNode')) != null ? _ref.data.key : void 0;
      if (typeof (_base = this.$().dynatree('getRoot')).removeChildren === "function") {
        _base.removeChildren();
      }
      this.updateTreeStateFromModel(this.$().dynatree('getRoot'), this.getPath('formDefinition.renderables'));
      for (_i = 0, _len = expandedNodePaths.length; _i < _len; _i++) {
        expandedNodePath = expandedNodePaths[_i];
        this.$().dynatree('getTree').getNodeByKey(expandedNodePath).expand(true);
      }
      return (_ref2 = this.$().dynatree('getTree').getNodeByKey(activeNodePath)) != null ? _ref2.activate(true) : void 0;
    }).observes('formDefinition.__nestedPropertyChange'),
    updateTreeStateFromModel: function(dynaTreeParentNode, currentListOfSubRenderables) {
      var newNode, subRenderable, _i, _len, _results;
      if (!currentListOfSubRenderables) return;
      _results = [];
      for (_i = 0, _len = currentListOfSubRenderables.length; _i < _len; _i++) {
        subRenderable = currentListOfSubRenderables[_i];
        newNode = dynaTreeParentNode.addChild({
          key: subRenderable.get('_path'),
          title: subRenderable.label ? subRenderable.label : subRenderable.identifier,
          formRenderable: subRenderable
        });
        _results.push(this.updateTreeStateFromModel(newNode, subRenderable.getPath('renderables')));
      }
      return _results;
    }
  });

  TYPO3.FormBuilder.View.FormElementInspector = Ember.ContainerView.extend({
    formElement: null,
    formElementType: (function() {
      var formElementTypeName;
      formElementTypeName = this.getPath('formElement.type');
      if (!formElementTypeName) return null;
      return TYPO3.FormBuilder.Model.FormElementTypes.get(formElementTypeName);
    }).property('formElement').cacheable(),
    orderedFormFieldEditors: (function() {
      var formFieldEditors, k, orderedFormFieldEditors, v;
      formFieldEditors = $.extend({}, this.getPath('formElementType.formFieldEditors'));
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
    }).property('formElementType').cacheable(),
    onFormElementChange: (function() {
      var formFieldEditor, subView, subViewClass, subViewOptions, _i, _len, _ref;
      this.removeAllChildren();
      if (!this.formElement) return;
      _ref = this.get('orderedFormFieldEditors');
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        formFieldEditor = _ref[_i];
        subViewClass = Ember.getPath(formFieldEditor.viewName);
        if (!subViewClass) {
          throw "Editor class '" + formFieldEditor.viewName + "' not found";
        }
        subViewOptions = $.extend({}, formFieldEditor, {
          formElement: this.formElement
        });
        console.log(subViewOptions);
        subView = subViewClass.create(subViewOptions);
        this.get('childViews').push(subView);
      }
      return this.rerender();
    }).observes('formElement')
  });

  TYPO3.FormBuilder.View.Editor = {};

  TYPO3.FormBuilder.View.Editor.AbstractEditor = Ember.View.extend({
    formElement: null
  });

  TYPO3.FormBuilder.View.Editor.LabelEditor = TYPO3.FormBuilder.View.Editor.AbstractEditor.extend({
    templateName: 'LabelEditor',
    label: (function(k, v) {
      if (v) {
        return this.setPath('formElement.label', v);
      } else {
        return this.getPath('formElement.label');
      }
    }).property('formElement').cacheable(),
    identifier: (function(k, v) {
      if (v) {
        return this.setPath('formElement.identifier', v);
      } else {
        return this.getPath('formElement.identifier');
      }
    }).property('formElement').cacheable()
  });

  TYPO3.FormBuilder.View.Editor.PropertyGrid = TYPO3.FormBuilder.View.Editor.AbstractEditor.extend({
    propertyPath: null,
    value: (function(k, v) {
      if (v) {
        return this.formElement.setPath(this.get('propertyPath'), v);
      } else {
        return this.formElement.getPath(this.get('propertyPath'));
      }
    }).property('propertyPath', 'formElement').cacheable(),
    valueChanged: function() {
      var _base;
      return typeof (_base = this.get('formElement')).somePropertyChanged === "function" ? _base.somePropertyChanged(this.formElement, this.get('propertyPath')) : void 0;
    },
    columns: null,
    options: {
      enableColumnReorder: false,
      autoHeight: true,
      editable: true,
      enableAddRow: true,
      enableCellNavigation: true,
      asyncEditorLoading: false,
      forceFitColumns: true
    },
    grid: null,
    didInsertElement: function() {
      var moveRowsPlugin,
        _this = this;
      this.grid = new Slick.Grid(this.$(), this.get('value'), this.columns, this.options);
      this.grid.setSelectionModel(new Slick.RowSelectionModel());
      this.grid.onCellChange.subscribe(function(e, args) {
        _this.get('value').replace(args.row, 1, args.item);
        return _this.valueChanged();
      });
      this.grid.onAddNewRow.subscribe(function(e, args) {
        var columnDefinition, newItem, _i, _len, _ref;
        _this.grid.invalidateRow(_this.get('value').length);
        newItem = {};
        _ref = _this.columns;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          columnDefinition = _ref[_i];
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
        var i, _ref;
        for (i = 0, _ref = data.rows.length; 0 <= _ref ? i < _ref : i > _ref; 0 <= _ref ? i++ : i--) {
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

  TYPO3.FormBuilder.View.FormPageView = Ember.View.extend({
    formPagesBinding: 'TYPO3.FormBuilder.Model.Form.formDefinition.renderables',
    currentPageIndex: 0,
    page: Ember.computed(function() {
      var _ref;
      return (_ref = this.get('formPages')) != null ? _ref.get(this.get('currentPageIndex')) : void 0;
    }).property('formPages', 'currentPageIndex').cacheable(),
    renderPageIfPageObjectChanges: (function() {
      var formDefinition, _ref,
        _this = this;
      if (!((_ref = TYPO3.FormBuilder.Model.Form.get('formDefinition')) != null ? _ref.get('identifier') : void 0)) {
        return;
      }
      formDefinition = TYPO3.FormBuilder.Utility.convertToSimpleObject(TYPO3.FormBuilder.Model.Form.get('formDefinition'));
      console.log("POST DATA");
      return $.post(TYPO3.FormBuilder.Configuration.endpoints.formPageRenderer, {
        formDefinition: formDefinition
      }, function(data) {
        _this.$().html(data);
        return _this.postProcessRenderedPage();
      });
    }).observes('page', 'page.__nestedPropertyChange'),
    postProcessRenderedPage: function() {
      return this.$().find('fieldset').addClass('typo3-form-sortable').sortable({
        revert: 'true'
      });
    }
  });

}).call(this);
