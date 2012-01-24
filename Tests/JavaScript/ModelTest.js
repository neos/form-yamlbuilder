describe('Model', function() {
	describe('Renderable', function() {
		var Renderable = TYPO3.FormBuilder.Model.Renderable;

		it('setPathRecursively should work', function() {
			var r = Renderable.create({
				'identifier': 'myIdentifier',
				'foo': 'myFoo'
			});
			r.setPathRecursively('properties.foo', 'bar')
			expect(r.getPath('properties.foo')).toEqual('bar');
		});
		describe('Renderable Hierarchy Maintenance', function() {
			it('should set properties correctly', function() {
				var r = Renderable.create({
					'identifier': 'myIdentifier',
					'foo': 'myFoo'
				});
				expect(r.get('identifier')).toEqual('myIdentifier');
				expect(r.get('foo')).toEqual('myFoo');
			});

			it('should create a "renderables" sub array which is initially empty', function() {
				var r = Renderable.create({
				});
				expect(r.get('renderables')).toEqual([]);
			})

			it('should create sub renderables if needed, connecting them to the parent renderable as needed', function() {
				var r = Renderable.create({
					renderables: [{
						'identifier': 'foo',
						'prop': 'bar'
					}]
				});
				expect(r.getPath('renderables.0.identifier')).toEqual('foo');
				expect(r.getPath('renderables.0.prop')).toEqual('bar');
				expect(r.getPath('renderables.0.parentRenderable')).toEqual(r);
			})

			it('should set the backreference to the parent renderable once it is added to a renderable', function() {
				var r = Renderable.create({ });
				var rSub = Renderable.create({
					'foo': 'bar'
				});
				expect(r.get('renderables').pushObject(rSub));
				expect(r.getPath('renderables.0.foo')).toEqual('bar');
				expect(r.getPath('renderables.0.parentRenderable')).toEqual(r);
				expect(rSub.get('parentRenderable')).toEqual(r);
			})

			it('should remove the backreference to the parent renderable once it is removed from a renderable', function() {
				var r = Renderable.create({
					renderables: [{
						'identifier': 'foo',
						'prop': 'bar'
					}]
				});
				var rSub = r.getPath('renderables.0');
				expect(rSub.get('identifier')).toEqual('foo');

				r.get('renderables').removeObject(rSub);

				expect(rSub.get('parentRenderable')).toEqual(null);
			})
		})

		describe('Renderable Change Event Listeners', function() {
			it('nested renderables should call parent event listeners correctly', function() {
				var somePropertyChangedCalledWithArguments = null

				var r = Renderable.create({
					renderables: [{
						'identifier': 'foo',
						'prop': 'bar'
					}],
					somePropertyChanged: function() {
						somePropertyChangedCalledWithArguments = arguments
					}
				});
				r.setPath('renderables.0.prop', 'asdf');
				expect(somePropertyChangedCalledWithArguments[0]).toEqual(r);
				expect(somePropertyChangedCalledWithArguments[1]).toEqual('renderables.0.prop');
			})

			it('added or modified properties should trigger change event listeners properly', function() {
				var somePropertyChangedCalledWithArguments = [];

				var r = Renderable.create({
					renderables: [{
						'identifier': 'foo',
						'prop': 'bar'
					}],
					somePropertyChanged: function() {
						somePropertyChangedCalledWithArguments.push(arguments)
					}
				});
				r.setPath('renderables.0.someNewProperty', 'myNewProperty');
				r.setPath('renderables.0.someNewProperty', 'myNewProperty2');
				expect(somePropertyChangedCalledWithArguments[0][0]).toEqual(r);
				expect(somePropertyChangedCalledWithArguments[0][1]).toEqual('renderables.0.someNewProperty');
				expect(somePropertyChangedCalledWithArguments[1][0]).toEqual(r);
				expect(somePropertyChangedCalledWithArguments[1][1]).toEqual('renderables.0.someNewProperty');
			});
		})
	});
});