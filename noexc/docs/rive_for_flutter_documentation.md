Runtime Fundamentals

Artboards
=========

Selecting an artboard at runtime

For more information on creating Artboards in Rive, please refer to: [Artboards](/docs/editor/fundamentals/artboards).

[​

](#choosing-an-artboard)

Choosing an artboard
----------------------------------------------------

When a Rive object is instantiated, the artboard to use can be specified. If no artboard is given, the [default artboard](/docs/editor/fundamentals/artboards#default-state-machine), as set in the Rive editor, is used. If no default artboard is set, the first artboard is used. Only one artboard can be used at a time.

*   Web
*   React
*   React Native
*   Flutter
*   Apple
*   Android

Manually create an artboard:

Copy

Ask AI

    // Default artboard
    final artboard = riveFile.defaultArtboard();
    // Artboard named
    final artboard = riveFile.artboard('Truck');
    // Artboard at index
    final artboard = riveFile.artboardAt(0);
    

Specify the artboard to use in `RiveWidgetController` or `RiveWidgetBuilder`:

Copy

Ask AI

    // Default artboard
    final artboardSelector = ArtboardSelector.byDefault();
    // Artboard named
    final artboardSelector = ArtboardSelector.byName('Truck');
    // Artboard at index
    final artboardSelector = ArtboardSelector.byIndex(0);
    
    // Pass to RiveWidgetController
    final controller = RiveWidgetController(
      riveFile,
      artboardSelector: artboardSelector,
    );
    
    // Pass to RiveWidgetBuilder
    return RiveWidgetBuilder(
      fileLoader: fileLoader,
      artboardSelector: ArtboardSelector.byName('Main'),
      builder: (context, state) {
        // return a widget
      },
    );  
    

Layout
======

Rive offers multiple options for controlling how graphics are laid out within the canvas, view, widget, or texture.

[​

](#responsive-layout)

Responsive Layout
----------------------------------------------

Rive’s new Layout feature lets you design resizable artboards with built-in responsive behavior, configured directly in the graphic. Just set a **Fit** of type **Layout** at runtime and the artboard will resize automatically. Optionally, provide a **Layout Scale Factor** to further adjust the scale of the content. For more Editor information and how to configure your graphic see [Layouts Overview](/docs/editor/layouts/layouts-overview).

The **Alignment** property will not have an effect when the using a **Fit** of type **Layout**.

*   Web
*   React
*   React Native
*   Flutter
*   Apple
*   Android

Pass the `Fit.layout` to the `RiveWidget` widget. This will automatically scale and resize the artboard to match the widget size. You can also set the `layoutScaleFactor` to control the scale of the artboard. This is useful for adjusting the size of the artboard when using `Fit.layout`.

Copy

Ask AI

    return RiveWidget(
      controller: controller,
      fit: Fit.layout,
      layoutScaleFactor: 2.0, // Optional: 2x scale of the layout,
    );
    

Alternatively, you can also set the `fit` and `layoutScaleFactor` properties directly on any `RivePainter`, such as the `RiveWidgetController`:

Copy

Ask AI

    final controller = RiveWidgetController(riveFile);
    controller.fit = Fit.layout;
    controller.layoutScaleFactor = 2.0; // Optional: 2x scale of the layout
    

[​

](#additional-layout-options)

Additional Layout Options
--------------------------------------------------------------

If the graphic doesn’t use Rive’s Layout feature, you can configure the layout with other **Fit** options and **Alignment** settings. See the sections below for more information on **Fit** and **Alignment**.

*   Web
*   React
*   React Native
*   Flutter
*   Apple
*   Android

Pass the `Fit` and `Alignment` to the `RiveWidget` widget.

Copy

Ask AI

    return RiveWidget(
      controller: controller,
      fit: Fit.contain,
      alignment: Alignment.center,
    );
    

Alternatively, you can also the set `fit` and `alignment` properties directly on any `RivePainter`, such as the `RiveWidgetController`:

Copy

Ask AI

    final controller = RiveWidgetController(riveFile);
    controller.fit = Fit.contain;
    controller.alignment = Alignment.center;
    

[​

](#fit)

Fit
------------------

Fit determines how the Rive content will be fitted to the view. There are a number of options available:

*   `Layout`: Rive content will be resized automatically based on layout constraints of the artboard to match the underlying view size. See [the above](/docs/runtimes/layout#responsive-layout) for more information on how to use this option.
*   `Cover`: Rive will cover the view, preserving the aspect ratio. If the Rive content has a different ratio to the view, then the Rive content will be clipped.
*   `Contain`: **(Default)** Rive content will be contained within the view, preserving the aspect ratio. If the ratios differ, then a portion of the view will be unused.
*   `Fill`: Rive content will fill the available view. If the aspect ratios differ, then the Rive content will be stretched.
*   `FitWidth`: Rive content will fill to the width of the view. This may result in clipping or unfilled view space.
*   `FitHeight`: Rive content will fill to the height of the view. This may result in clipping or unfilled view space.
*   `None`: Rive content will render to the size of its artboard, which may result in clipping or unfilled view space.
*   `ScaleDown`: Rive content is scaled down to the size of the view, preserving the aspect ratio. This is equivalent to `Contain` when the content is larger than the canvas. If the canvas is larger, then `ScaleDown` will not scale up.

[​

](#alignment)

Alignment
------------------------------

Alignment determines how the content aligns with respect to the view bounds. The following options are available:

*   `Center` **(Default)**
*   `TopLeft`
*   `TopCenter`
*   `TopRight`
*   `CenterLeft`
*   `CenterRight`
*   `BottomLeft`
*   `BottomCenter`
*   `BottomRight`

[​

](#bounds)

Bounds
------------------------

The bounds for the area in which the Rive content will render can be set by providing the minimum and maximum x and y coordinates. These coordinates are relative to the view in which the Rive content is contained, and all must be provided. These will override alignment settings.

*   `minX`
*   `minY`
*   `maxX`
*   `maxY`

State Machine Playback
======================

Playing a state machine

For more information on designing and building state machines in Rive, please refer to: [State Machine](/docs/editor/state-machine). Rive’s state machines provide a way to combine a set of animation states and manage the transition between them that can be programmatically controlled with [Data Binding](/docs/runtimes/data-binding) (recommended) and [Inputs](/docs/runtimes/inputs).

[​

](#playing-state-machines)

Playing state machines
--------------------------------------------------------

State machines are instantiated by providing a state machine name to the Rive object when instantiated.

*   Web
*   React
*   React Native
*   Flutter
*   Apple
*   Android

There are a number of ways to play/select a state machine in Flutter.

#### 

[​

](#when-using-rivewidgetcontroller-recommended)

When using `RiveWidgetController` (recommended)

When you create a `RiveWidgetController` it will use the default state machine, or you can specify a state machine by name or index.

Copy

Ask AI

    // Default state machine
    var controller = RiveWidgetController(riveFile);
    // By name
    controller = RiveWidgetController(
      riveFile,
      stateMachineSelector: StateMachineSelector.byName("State Machine 1"),
    );
    // By index
    controller = RiveWidgetController(
      riveFile,
      stateMachineSelector: StateMachineSelector.byIndex(0),
    );
    

Passing this controller to a `RiveWidget` will automatically play the state machine.

Copy

Ask AI

    @override
    Widget build(BuildContext context) {
      return RiveWidget(controller: controller);
    }
    

You can mark the controller as `active` to play/pause the state machine (advancing and drawing):

Copy

Ask AI

    final controller = RiveWidgetController(riveFile);
    controller.active = false;
    

The `StateMachineSelector` can also be passed to `RiveWidgetBuilder` to specify which state machine to use:

Copy

Ask AI

    return RiveWidgetBuilder(
      fileLoader: fileLoader,
      stateMachineSelector: StateMachineSelector.byIndex(0),
      builder: (context, state) => switch (state) {
        /// ...
      },
    );
    

#### 

[​

](#when-using-statemachinepainter)

When using `StateMachinePainter`

When using `StateMachinePainter`, you can specify the state machine to use by passing an optional name.

Copy

Ask AI

    // Default state machine
    final painter = rive.StateMachinePainter(withStateMachine: _withStateMachine);
    // By name
    painter = rive.StateMachinePainter(
      withStateMachine: _withStateMachine,
      stateMachineName: 'State Machine 1  ',
    );    
    

#### 

[​

](#creating-a-state-machine-directly)

Creating a state machine directly

Create the state machine directly from an `Artboard`:

Copy

Ask AI

    final artboard = riveFile.defaultArtboard()!;
    // Default state machine
    var stateMachine = artboard.defaultStateMachine();
    // By name
    stateMachine = artboard.stateMachine('State Machine 1');
    // By index
    stateMachine = artboard.stateMachineAt(0);
    

[​

](#state-change-event-callback)

State change event callback
------------------------------------------------------------------

*   Web
*   React
*   Flutter
*   Apple
*   Android

Not supported. This is a legacy feature and we strongly recommend using [Data Binding](/docs/runtimes/data-binding) or [Events](/docs/runtimes/rive-events) instead.

Data Binding
============

Connect your code to bound editor elements using View Models

[​

](#overview)

Overview
============================

Before engaging with the runtime data binding APIs, it is important to familiarize yourself with the core concepts presented in the [Overview](/docs/editor/data-binding/overview).[

Data Binding Concepts
---------------------

An overview of core data binding concepts.





](/docs/editor/data-binding/overview)

[​

](#view-models)

View Models
==================================

View models describe a set of properties, but cannot themselves be used to get or set values - that is the role of [view model instances](#view-model-instances). To begin, we need to get a reference to a particular view model. This can be done either by index, by name, or the default for a given artboard, and is done from the Rive file. The default option refers to the view model assigned to an artboard by the dropdown in the editor.

*   Web
*   React
*   Apple
*   Android
*   Flutter
*   Unity
*   React Native

Copy

Ask AI

    // Get reference to the File and Artboard
    final file = await File.asset(
        'assets/my_file.riv',
        riveFactory: Factory.rive,
    );
    final artboard = file!.defaultArtboard()!;
    
    // Get reference by name
    file.viewModelByName("My View Model");
    
    // Get reference by index
    for (var i = 0; i < file.viewModelCount; i++) {
        final indexedVM = file.viewModelByIndex(i);
    }
    
    // Get reference to the default view model for an artboard
    final defaultVM = file.defaultArtboardViewModel(artboard);
    
    // Dispose the view model when you're no longer using it
    viewModel.dispose();
    

[​

](#view-model-instances)

View Model Instances
====================================================

Once we have a reference to a view model, it can be used to create an instance. When creating an instance, you have four options:

1.  Create a blank instance - Fill the properties of the created instance with default values as follows:
    
    Type
    
    Value
    
    Number
    
    0
    
    String
    
    Empty string
    
    Boolean
    
    False
    
    Color
    
    0xFF000000
    
    Trigger
    
    Untriggered
    
    Enum
    
    The first value
    
    Nested view model
    
    Null
    
2.  Create the default instance - Use the instance labelled “Default” in the editor. Usually this is the one a designer intends as the primary one to be used at runtime.
3.  Create by index - Using the order returned when iterating over all available instances. Useful when creating multiple instances by iteration.
4.  Create by name - Use the editor’s instance name. Useful when creating a specific instance.

*   Web
*   React
*   Apple
*   Android
*   Flutter
*   Unity
*   React Native

Copy

Ask AI

    final vm = file.viewModelByName("My View Model")!;
    
    // Create blank
    final vmiBlank = vm.createInstance();
    
    // Create default
    final vmiDefault = vm.createDefaultInstance();
    
    // Create by index
    for (int i = 0; i < vm.instanceCount; i++) {
    final vmiIndexed = vm.createInstanceByIndex(i);
    }
    
    // Create by name
    final vmiNamed = vm.createInstanceByName("My Instance");
    
    // Dispose the view model instance
    viewModelInstance.dispose();
    

The created instance can then be assigned to a state machine or artboard. This establishes the bindings set up at edit time. It is preferred to assign to a state machine, as this will automatically apply the instance to the artboard as well. Only assign to an artboard if you are not using a state machine, i.e. your file is static or uses linear animations.

The initial values of the instance are not applied to their bound elements until the state machine or artboard advances.

*   Web
*   React
*   Apple
*   Android
*   Flutter
*   Unity
*   React Native

Copy

Ask AI

    final file = await File.asset(
    'assets/my_file.riv',
    riveFactory: Factory.rive,
    );
    
    final artboard = file!.defaultArtboard();
    final stateMachine = artboard!.defaultStateMachine()!;
    
    final vm = file.defaultArtboardViewModel(artboard)!;
    final vmi = vm.createDefaultInstance()!;
    
    // Bind to the state machine. This automatically binds to the artboard as well.
    stateMachine.bindViewModelInstance(vmi);
    
    // If you're not using a state machine, bind to the artboard
    artboard.bindViewModelInstance(vmi);
    

### 

[​

](#auto-binding)

Auto-Binding

Alternatively, you may prefer to use auto-binding. This will automatically bind the default view model of the artboard using the default instance to both the state machine and the artboard. The default view model is the one selected on the artboard in the editor dropdown. The default instance is the one marked “Default” in the editor.

*   Web
*   React
*   Apple
*   Android
*   Flutter
*   Unity
*   React Native

// Get reference to the File
file = await File.asset(
    'assets/rewards.riv',
    riveFactory: Factory.rive,
);

// Create a controller
controller = RiveWidgetController(file!);

// Auto data bind
viewModelInstance = controller.dataBind(DataBind.auto());

// Dispose of objects you created when no longer needed
viewModelInstance.dispose();
controller.dispose();
file.dispose();

[​

](#properties)

Properties
================================

A property is a value that can be read, set, or observed on a view model instance. Properties can be of the following types:

Type

Supported

Floating point numbers

✅

Booleans

✅

Triggers

✅

Strings

✅

Enumerations

✅

Colors

✅

Nesting

✅

Lists

✅

Images

✅ Early Access

Property descriptors can be inspected on a view model to discover at runtime which are available. These are not the mutable properties themselves though - once again those are on instances. These descriptors have a type and name.

*   Web
*   React
*   Apple
*   Android
*   Flutter
*   Unity
*   React Native

Copy

Ask AI

    // Accesss on a ViewModel object
    print("Properties: ${viewModel.properties}");
    
    // Access on a ViewModelInstance object
    print("Properties: ${viewModelInstance.properties}");
    

References to these properties can be retrieved by name or path. Some properties are mutable and have getters, setters, and observer operations for their values. Getting or observing the value will retrieve the latest value set on that property’s binding, as of the last state machine or artboard advance. Setting the value will update the value and all of its bound elements.

After setting a property’s value, the changes will not apply to their bound elements until the state machine or artboard advances.

*   Web
*   React
*   Apple
*   Android
*   Flutter
*   Unity
*   React Native

Copy

Ask AI

    final vm = file.defaultArtboardViewModel(artboard)!;
    final vmi = vm.createDefaultInstance()!;
    
    final numberProperty = vmi.number("My Number Property")!;
    // Get
    final numberValue = numberProperty.value;
    
    // Set
    numberProperty.value = 10;
    
    // Observe
    void onNumberChange(double value) {
        print("Number changed to: $value");
    }
    numberProperty.addListener(onNumberChange);
    
    // Remove listener when done
    numberProperty.removeListener(onNumberChange);
    
    // Alternatively, clear all listeners
    numberProperty.clearListeners();
    
    // Dispose of the property to clear up resources when you're no longer using it
    // This will call `clearListeners()` internally.
    numberProperty.dispose();
    

### 

[​

](#nested-property-paths)

Nested Property Paths

View models can have properties of type view model, allowing for arbitrary nesting. You can chain property calls on each instance starting from the root until you get to the property of interest. Alternatively, you can do this through a path parameter, which is similar to a URI in that it is a forward slash delimited list of property names ending in the name of the property of interest.

*   Web
*   React
*   Apple
*   Android
*   Flutter
*   Unity
*   React Native

Copy

Ask AI

    final vm = file.viewModelByName("My View Model")!;
    final vmi = vm.createInstanceByName("My Instance")!;
    
    final nestedNumberByChain = vmi
        .viewModel("My Nested View Model")!
        .viewModel("My Second Nested VM")!
        .number("My Nested Number");
    
    final nestedNumberByPath = vmi.number("My Nested View Model/My Second Nested VM/My Nested Number");
    

### 

[​

](#observability)

Observability

You can observe changes over time to property values, either by using listeners or a platform equivalent method. Once observed, you will be notified when the property changes are applied by a state machine advance, whether that is a new value that has been explicitly set or if the value was updated as a result of a binding. Observing trigger properties is an alternative method to receive events from the editor, as compared to [Rive Events](/docs/runtimes/rive-events).

*   Web
*   React
*   Apple
*   Android
*   Flutter
*   Unity
*   React Native

Copy

Ask AI

    final vm = file.defaultArtboardViewModel(artboard)!;
    final vmi = vm.createDefaultInstance()!;
    
    final numberProperty = vmi.number("My Number Property")!;
    // Get
    final numberValue = numberProperty.value;
    
    // Set
    numberProperty.value = 10;
    
    // Observe
    void onNumberChange(double value) {
        print("Number changed to: $value");
    }
    numberProperty.addListener(onNumberChange);
    
    // Remove listener when done
    numberProperty.removeListener(onNumberChange);
    
    // Alternatively, clear all listeners
    numberProperty.clearListeners();
    
    // Dispose of the property to clear up resources when you're no longer using it
    // This will call `clearListeners()` internally.
    numberProperty.dispose();
    

### 

[​

](#images)

Images

Image properties let you set and replace raster images at runtime, with each instance of the image managed independently. For example, you could build an avatar creator and dynamically update features — like swapping out a hat — by setting a view model’s image property.

*   Web
*   React
*   Apple
*   Flutter
*   Unity
*   React Native

Copy

Ask AI

    // Access the image property by path on a ViewModelInstance object
    final imageProperty = viewModelInstance.image('my_image')!; // image property named "my_image"
    
    // Create a RenderImage
    final renderImage = await Factory.rive.decodeImage(bytes); // use `Factory.flutter` if you're using the Flutter renderer
    
    // If the image is valid, update the image property value
    if (renderImage != null) {
        imageProperty.value = renderImage;
    }
    
    // You can also set the image property to null to clear it
    imageProperty.value = null;
    

### 

[​

](#lists)

Lists

List properties let you manage a dynamic set of view model instances at runtime. For example, you can build a TODO app where users can add and remove tasks in a scrollable Layout. See the [Editor section](/docs/editor/data-binding/lists) on creating data bound lists. A single list property can include different view model types, with each view model tied to its own Nested Artboard, making it easy to populate a list with a varity of Nested Artboards. With list properties, you can:

*   Add a new view model instance (optionally at an index)
*   Remove an existing view model instance (optionally by index)
*   Swap two view model instances by index
*   Get the size of a list

For more information on list properties, see the [Data Binding List Property](/docs/editor/data-binding/lists#view-model-list-property) editor documentation.

*   Web
*   React
*   Apple
*   Flutter
*   Unity
*   React Native

The list API in Flutter is designed to be similar to the [List](https://api.dart.dev/dart-core/List-class.html) class in Dart. It doesn’t contain the full API spec of that class, but it does provide the most commonly used methods.

Working with lists can result in errors ([`RangeError`](https://api.flutter.dev/flutter/dart-core/RangeError-class.html)) being thrown if you try to access an index that is out of bounds, or perform other list operations that are not permitted. Similar to the Dart List API.

Access a list property by path on a `ViewModelInstance` object:

Access a List property

Copy

Ask AI

    final todosProperty = viewModelInstance.list('todos')!; // list property named "todos"
    print(todosProperty.length); // print the length of the list
    

To add an item you first need to create an instance of the view model that you want to add to the list:

Create a blank view model instance

Copy

Ask AI

    final todoItemVM = riveFile.viewModelByName("TodoItem")!;
    final todoItemInstance = todoItemVM.createInstance()!;
    

You can also create an instance from an existing instance (as exported in the Rive Editor), using:

*   `createDefaultInstance()`
*   `createInstanceByName('exercise')`
*   `createInstanceByIndex(0)`.

Then add the instance to the list:

Add an instance to the list

Copy

Ask AI

    todosProperty.add(todoItemInstance);
    

To remove a particular instance from the list, you can use the `remove` method:

Remove an instance from the list

Copy

Ask AI

    todosProperty.remove(todoItemInstance);
    

Other operations:

List operations

Copy

Ask AI

    // Remove at index
    todosProperty.removeAt(0); // can throw
    
    // Insert at index
    todosProperty.insert(0, todoItemInstance); // can throw
    
    // Swap
    todosProperty.swap(0, 1); // can throw
    
    // First
    ViewModelInstance todo = todosProperty.first(); // can throw
    
    // Last
    ViewModelInstance todo = todosProperty.last(); // can throw
    
    // First or null
    ViewModelInstance? todo todosProperty.firstOrNull(); // will return null if the list is empty
    
    // Last or null
    ViewModelInstance? todosProperty.lastOrNull(); // will return null if the list is empty
    
    // Access/set directly by index
    final instance = todosProperty[0]; // can throw
    todosProperty[0] = todoItemInstance; // can throw
    
    // Instance at index
    todosProperty.instanceAt(2); // can throw
    
    // Length
    todosProperty.length;
    

### 

[​

](#artboards)

Artboards

Artboard properties allows you to swap out entire nested artboards (components) at runtime. This is useful for creating modular components that can be reused across different designs or applications, for example:

*   Creating a skinning system that supports a large number of variations, such as a character creator where you can swap out different body parts, clothing, and accessories.
*   Creating a complex scene that is a composition of various artboards loaded from various different Rive files (drawn to a single canvas/texture/widget).
*   Reducing the size (complexity) of a single Rive file by breaking it up into smaller components that can be loaded on demand and swapped in and out as needed.

*   Web
*   React
*   Apple
*   Flutter
*   Unity
*   React Native

Supported. Documentation coming soon.

### 

[​

](#enums)

Enums

Enums properties come in two flavors: system and user-defined. In practice, you will not need to worry about the distinction, but just be aware that system enums are available in any Rive file that binds to an editor-defined enum set, representing options from the editor’s dropdowns, where user-defined enums are those defined by a designer in the editor. Enums are string typed. The Rive file contains a list of enums. Each enum in turn has a name and a list of strings.

*   Web
*   React
*   Android
*   Flutter
*   Unity
*   React Native

Copy

Ask AI

    // Accesss on a File object
    print("Data enums: ${file.enums}");
    

Data Binding Overview
=====================

Connect editor elements to data and code using View Models

[​

](#what-is-data-binding%3F)

What is Data Binding?
========================================================

Data binding is a powerful way to create reactive connections between editor elements, data, and code. For instance, you might:

*   Bind the color of an icon to a color data property that can be adjusted by a developer at runtime
*   Bind the X-position of an animated object so that it can be followed with an offset by another object
*   Listen for a click event on two buttons to increment and decrement a counter

[​

](#why-use-data-binding%3F)

Why Use Data Binding?
========================================================

Data binding decouples design and code by introducing intermediate data that both sides can bind to. This forms the “contract” between designers and developers. Once this contract is in place, both sides can iterate independently, speeding your ability to deliver new features and experiment with what’s possible. Within the editor, data binding allows for more reactivity in your designs. You can establish relationships between objects and ensure that certain invariants hold true, no matter the state of the artboard. The data binding system will ensure that these relationships are always up to date as animations and calls from code change the values. It also offers the opportunity to shift more logic into the Rive file and out of code. You will need to decide whether a piece of logic lives in code or data binding for your given use case, but one consideration is that any data binding logic will be universal across runtimes, rather than needing separate re-implementations.


[​

](#introduction)

Introduction

### 

[​

](#view-models)

View Models

### 

[​

](#number-properties)

Number Properties

### 

[​

](#string-properties)

String Properties

### 

[​

](#color-properties)

Color Properties

### 

[​

](#binding-state-machine-conditions)

Binding State Machine Conditions

[​

](#glossary)

Glossary
============================

Data binding introduces a number of concepts that you will need to familiarize yourself with. The names of these concepts are loosely derived from the Model, View, Viewmodel (MVVM) pattern in software development.

### 

[​

](#editor-element)

Editor Element

For the purposes of data binding, an “editor element” simply refers to an editable UI element in the editor with a value that can have a binding attached to it.

### 

[​

](#view-model)

View Model

A view model is a blueprint for a collection of data. Developers might think of this as similar to a class in object-oriented programming. View models typically describe all of the associated data with a given use case - commonly one per artboard. View models themselves don’t have concrete values. For that, you must have [an instance](#view-model-instance).

### 

[​

](#view-model-property)

View Model Property

A view model property is one piece of data within a view model. Developers might think of this as similar to a field in object-oriented programming. Properties have a data type which is selected when they are created and a name which can be referenced in code. Each property can be bound to different editor elements of the same type.

### 

[​

](#view-model-instance)

View Model Instance

A view model instance is the living version of a view model with actual values. Developers might think of this as similar to a class instance in object-oriented programming. Instances have the same properties as the view model they are derived from, except now each of these properties has a living value that can change over time. You may create as many instances as you’d like from a given view model. Each can be given a unique name associated with what those values represent. Each can have different initial values for its properties, representing a design-time configuration. For example, if you had a menu with three buttons with icons: 🏠 Home, 👤 Profile, and ❓ About, you might have a single artboard representing the menu item, but three view model instances, each with the menu item’s label and associated icon, that can be applied to that artboard to configure the buttons. Artboards are assigned an instance to populate the data bindings. Changing which instance is applied will change the initial state of the properties and all associated bound elements. In order for an instance to be visible to developers, it must be marked as Exported. Otherwise, it is considered internal to the file. One reason you may want to keep it internal is if you only use the instance to test your design when it is configured with a given set of values, including edge cases. These exported instances can then be assigned to an artboard at runtime by developers. Alternatively, developers can create empty instances which have default values, such as zero for numbers and empty strings. Once the instance is assigned, its values will begin updating according to the bindings.

### 

[​

](#binding)

Binding

A binding is an association between a property and an editor element. For instance, you might have a property named “Name” bound to a text run’s text value. Bindings can be source to target, target to source, or bidirectional. In this case, “source” means the property, and “target” means the editor element. The default binding is source to target. This means that changes to the property update the value of the element. For example, an XPos property updates the X position of an object. Target to source means that changes to the element’s value update the property. For example, the X position of an object updates the XPos property. Bidirectional means that changes are applied in both directions, meaning either the element or the property can update the other. Additionally, a binding may be marked as “Bind Once”. This means that the initial value will apply and thereafter the binding will not apply any updates.

### 

[​

](#view-model-nesting)

View Model Nesting

View models can have another view model as one of their properties. This is referred to as “nesting”. This is useful when a parent instance wants to associate with a particular child instance, similar to nested artboards.

### 

[​

](#enumeration-enum)

Enumeration (Enum)

An enum represents a fixed set of options, similar to a drop-down. Use this property type to constrain the available values to a known, unchanging set. Enum properties can be either a “system” enum, in which case they represent a fixed set of options in the editor, such as the “Horizontal Align” options, or a “user defined” enum, in which case they can represent any fixed set of options applicable to your use case.

### 

[​

](#converter)

Converter

A converter is a general purpose way of transforming a binding’s value when it is applied. These transformations might involve changing its type. For instance, the “Convert to String” converter can be used to convert a numerical binding to text, so that an object’s X position could be applied to a text run. To apply a converter on a value that already has a binding, right click on the bound property, click Update Bind, and select your converter from the Convert dropdown.

[​

](#comparing-to-existing-features)

Comparing to Existing Features
========================================================================

Data binding fills some of the same roles as existing features in Rive. In general, it is considered a more powerful alternative to both inputs and events, and we recommend you adopt it for most use cases going forward. However, this does not mean that you need to retrofit existing files as they will continue to work as expected.

### 

[​

](#type-support)

Type Support

View model properties can represent more types of data compared to inputs and events. See below for a comparison.

Inputs

Events

View Model Properties

Floating point numbers

✅

✅

✅

Booleans

✅

✅

✅

Triggers

✅

❌

✅

Strings

❌

✅

✅

Enumerations

❌

❌

✅

Colors

❌

❌

✅

Nesting

❌

❌

✅

Lists

❌

❌

✅

Images

❌

❌

🚧 Coming soon

### 

[​

](#state-machine-inputs)

State Machine Inputs

Before data binding, state machine inputs were the primary way for developers to affect designs. They formed the “input” side of the contract with design. View model properties are a more flexible system. Inputs can only be used to drive state machine transitions, whereas data binding can be used to drive most editor elements in Rive and state machine transitions. Inputs must be used as-is where data-bound properties can be converted, either before being used by developers or before being applied to editor elements. View model properties also support both polling and listening APIs for developers, whereas inputs only support polling. This means that developers can more naturally react to changes in data. View model properties can also be used in two features currently used by inputs, that being blended states (both Blend 1D and Blend Additive) as the mix parameter and as the receiver for listeners, e.g. setting a value on a mouse click or tap.

### 

[​

](#events)

Events

The counterpart to inputs, events were the primary way for developers to receive “outputs” from designs. Data binding is a much richer channel for developers to observe values from the Rive design. Additionally, events were used internally in Rive files to add reactivity using listeners. Both of these use cases are addressed by properties. For developers, the runtime APIs allow you to subscribe to changes to their values. For designers, you can bind reacting elements directly to the property. Events can only be triggered by timelines, state machine transitions, or listeners. By comparison, data bound properties can be changed from any number of sources. Events can have keyable properties with values that are passed when triggered. This is limited to being updated by animation keys and can be tricky to “bubble” when the animation exists on a nested artboard. By comparison, view model properties carry the most recent data each time they change, from any level of the hierarchy, triggering a developer’s listener with the new value. One use case which events offer functionality not yet supported by data binding is in their ability to play audio.

### 

[​

](#constraints)

Constraints

Constraints allow for a specific kind of binding between two objects, such as Translation for position. This constraint is optimized for that use case, with built in options for local/world space conversion, a strength parameter, minimum and maximum values, etc. For use cases where this is all you need, this is likely to be the more concise option. By comparison, for example, data binding the X and Y positions can be used for a broader range of output behavior, though it may require some setup with converters to achieve.

### 

[​

](#nesting)

Nesting

There are a few use cases related to nesting where you may want to consider updating to use data binding, as it offers a much more straightforward approach:

*   Setting nested inputs
*   Setting nested text runs
*   “Bubbling” nested events

These three use cases are unified by view model instances, where nested artboards can pull from top-level viewmodels. This simplifies the developer interop, as the structure, naming, and nesting of the file’s artboards can change without breaking the code’s reference to the data.

Loading Assets
==============

Loading and replacing assets dynamically at runtime

Some Rive files may contain assets that can be embedded within the actual file binary, such as font, image, or audio files. The Rive runtimes may then load these assets when the Rive file is loaded. While this makes for easy usage of the Rive files/runtimes, there may be opportunities to load these assets in or even replace them at runtime instead of embedding them in the file binary. There are several benefits to this approach:

*   Keep the `.riv` files tiny without potential bloat of larger assets
*   Dynamically load an asset for any reason, such as loading an image with a smaller resolution if the `.riv` is running on a mobile device vs. an image of a larger resolution for desktop devices
*   Preload assets to have available immediately when displaying your `.riv`
*   Use assets already bundled with your application, such as font files
*   Sharing the same asset between multiple `.riv`s

[​

](#methods-for-loading-assets)

Methods for Loading Assets
----------------------------------------------------------------

There are currently three different ways to load assets for your Rive files. In the Rive editor select the desired asset from the **Assets** tab, and in the inspector choose the desired export option: ![Image](https://mintlify.s3.us-west-1.amazonaws.com/rive/images/runtimes/df455228-a712-4cff-a24d-0771b8575e9d.webp) See the **Export Options** section in the editor docs for more details.

### 

[​

](#embedded-assets)

Embedded Assets

In the Rive editor, static assets can be included in the `.riv` file, by choosing the _“Embedded”_ export type. As stated in the beginning of this page, when the Rive file gets loaded, the runtime will implicitly attempt to load in the assets embedded in the `.riv` as well, and you don’t need to concern yourself with loading any assets manually. **Caveat:** Embedded assets may bulk up the file size, especially when it comes to fonts when using Rive Text ([Text Overview](/docs/editor/text/text-overview)).

**Embedded is the default option.**

### 

[​

](#loading-via-rive%E2%80%99s-cdn)

Loading via Rive’s CDN

In the Rive editor, you can mark an imported asset as a _“Hosted”_ export type, which means that when you export the `.riv` file, the asset will not be embedded in the file binary, but will be hosted on Rive’s CDN. This means that at runtime when loading in the file, the runtime will see the asset is marked as “Hosted” and load the asset in from the Rive CDN, so that you don’t need need to concern yourself with loading anything yourself, and the file can still remain tiny. **Caveat:** The app will make an extra call to a Rive CDN to retrieve your asset

### 

[​

](#image-cdns)

Image CDNs

Some image CDNs allow for on-the-fly image transformations, including resizing, cropping, and automatic format conversion based on the browser’s and device’s capabilities. These CDNs can host your Rive image assets. Note that for these CDNs, you may need to specify the accepted formats, for example, as part of the HTTP header request:

Copy

Ask AI

    ...
    headers: {
      Accept: 'image/png,image/webp,image/jpeg,*/*',
    }
    ...
    

Please see your CDN provider’s documentation for additional information.

Rive support the following image formats: **jpeg**, **png**, and **webp**

### 

[​

](#referenced-assets)

Referenced Assets

In the Rive editor, you can mark an imported asset as a _“Referenced”_ export type, which means that when you export the `.riv` file, the asset will not be embedded in the file binary, and the responsibility of loading the asset will be handled by your application at runtime. This option enables you to dynamically load in assets via a handler API when the runtime begins loading in the `.riv` file. This option is preferable if you have a need to dynamically load in a specific asset based on any kind of app/game logic, and especially if you want to keep file size small. All referenced assets, including the `.riv`, will be bundled as a zip file when you export your animation. **Caveat:** You will need to provide an asset handler API when loading in Rive which should do the work of loading in an asset yourself. See Handling Assets below.

[​

](#handling-assets)

Handling Assets
------------------------------------------

See below for documentation on how to handle loading in assets at runtime for your Rive file with various runtimes.

*   Web (JS)
*   React
*   Flutter
*   Apple
*   Android
*   React Native

### 

[​

](#examples-3)

Examples

*   [Swap out fonts dynamically](https://zapp.run/edit/rive-out-of-band-assets-fonts-zva0062lva10)
*   [Swap out images dynamically](https://zapp.run/edit/rive-out-of-band-assets-image-z09q06hl09r0?entry=lib/main.dart&file=pubspec.yaml:2865-2888)

### 

[​

](#using-the-asset-handler-api-3)

Using the Asset Handler API

When instantiating a `File`, add an `assetLoader` callback to the list of parameters. This callback will be called for every asset the runtime detects from the `.riv` file on load, and will be responsible for either handling the load of an asset at runtime or passing on the responsibility and giving the runtime a chance to load it otherwise.

Font Asset Example

Copy

Ask AI

    final fontFile = await File.asset(
        'assets/acqua_text_out_of_band.riv',
        riveFactory: Factory.rive,
        assetLoader: (asset, bytes) {
            // Replace font assets that are not embedded in the rive file
            if (asset is FontAsset && bytes == null) {
                final urls = [
                    'https://cdn.rive.app/runtime/flutter/IndieFlower-Regular.ttf',
                    'https://cdn.rive.app/runtime/flutter/comic-neue.ttf',
                    'https://cdn.rive.app/runtime/flutter/inter.ttf',
                    'https://cdn.rive.app/runtime/flutter/inter-tight.ttf',
                    'https://cdn.rive.app/runtime/flutter/josefin-sans.ttf',
                    'https://cdn.rive.app/runtime/flutter/send-flowers.ttf',
                ];
    
                // pick a random url from the list of fonts
                http.get(Uri.parse(urls[Random().nextInt(urls.length)])).then((res) {
                    if (mounted) {
                        asset.decode(
                            Uint8List.view(res.bodyBytes.buffer),
                        );
                        setState(() {
                            // force rebuild in case the Rive graphic is no longer advancing
                        });
                    }
                });
                return true; // Tell the runtime not to load the asset automatically
            } else {
                // Tell the runtime to proceed with loading the asset if it exists
                return false;
            }
        },
    );
    

Your provided callback will be passed an `asset` and `bytes`.

*   `asset` - Reference to a `FileAsset` object. You can grab a number of properties from this object, such as the name, asset type, and more. You’ll also use this to set a new Rive specific asset for dynamically loaded content. Types: `FontAsset`, `ImageAsset`, and `AudioAsset`.
*   `bytes` - Array of bytes for the asset (if it’s available as an embedded asset)

**Example Usage**

*   See the Rive Flutter example app that shows how to pre-cache fonts and images, and dynamically swap them out at runtime.

**Important**: Note that the return value is a `boolean`, which is where you need to return:

*   `true` if you intend on handling and loading in an asset yourself
*   or `false` if you do not want to handle asset loading for that given asset yourself, and attempt to have the runtime try to load the asset

Once the `File` is disposed, the `FileAsset` will no longer be valid and would be dangerous to use.

Caching a Rive File
===================

Under most circumstances a `.riv` file should load quickly and managing the `RiveFile` yourself is not necessary. But if you intend to use the same `.riv` file in multiple parts of your application, or even on the same screen, it might be advantageous to load the file once and keep it in memory.

[​

](#example-usage)

Example Usage
--------------------------------------

*   Flutter
*   React
*   React Native
*   Web
*   Apple
*   Android

In Flutter, you are responsible for managing the lifecycle of a Rive file. You can create a `File` object directly, or use the `FileLoader` convenience class with `RiveWidgetBuilder`. In both cases, you must call `dispose()` on the object when it’s no longer needed to free up memory.

To optimize memory usage, reuse the same `File` object across multiple `RiveWidget` instances if they use the same `.riv` file. This ensures the file is loaded only once and shared in memory.

After a `File` is disposed, it cannot be used again. To use the same `.riv` file, create a new `File` object.

#### 

[​

](#managing-state)

Managing State

How you keep the Rive `File` alive and share it with widgets depends on your state management approach. For global access, load the file in `main` or during app startup, and expose it using a package like [Provider](https://pub.dev/packages/provider). If the file is only needed in a specific part of your app, consider loading the file only when required.

#### 

[​

](#memory)

Memory

Managing the file yourself gives you fine-grained control over memory usage, especially when the same Rive file is used in multiple places or simultaneously in several widgets. Use [Flutter DevTools memory tooling](https://docs.flutter.dev/tools/devtools/memory#memory-view-guide) to monitor and optimize memory if needed.

#### 

[​

](#network-assets)

Network Assets

To load a Rive file from the Internet, use `File.url('YOUR:URL')`. For network assets, cache the file in memory to avoid repeated downloads and unnecessary decoding of the file.

Playing Audio
=============

To learn more on how to add audio to your Rive file, see [Audio Events](/editor/events/audio-events).

On web, some browsers restrict audio from playing until the web page is interacted with. This applies to any audio, not just Rive audio.  
The web page needs to receive some interaction (touch/click) before sound is played. This interaction can be anything on the browser and doesn’t need to be a Rive specific interaction.

[​

](#embedded-assets)

Embedded Assets
------------------------------------------

Embedded assets require no additional work to play audio. However, on some platforms, additional work may be required to set up audio to mix, duck, or otherwise change more global settings for playing audio. See **Audio Settings** below.

[​

](#referenced-assets)

Referenced Assets
----------------------------------------------

Referenced assets require a little bit more work to play audio. Audio will still automatically play, but the audio file(s) must be loaded when a Rive runtime attempts to play audio. For more information, see [Loading Assets](/docs/runtimes/loading-assets).

*   Apple

IOS

Copy

Ask AI

    // Load a referenced audio file, with the same name and extension as added in the editor
    let viewModel = RiveViewModel(fileName: "my_rive_file") { asset, data, factory -> Bool in
        guard let audioAsset = asset as? RiveAudioAsset else {
            return false
        }
    
        guard let url = Bundle.main.url(
            forResource: audioAsset.uniqueName(),
            withExtension: audioAsset.fileExtension()
        ) else {
            print("Failed to load asset \(asset.uniqueFilename()) from bundle.")
            return false
        }
    
        guard let data = try? Data(contentsOf: url) else {
            print("Failed to load \(url) from bundle.")
            return false
        }
    
        audioAsset.audio(factory.decodeAudio(data))
        return true
    }
    

[​

](#audio-settings)

Audio Settings
----------------------------------------

*   Apple

On iOS, playing audio will respect your `AVAudioSession` shared instance settings. For more information, see [Apple’s documentation](https://developer.apple.com/documentation/avfaudio/avaudiosession) on `AVAudioSession`. Using this, you can choose to mix audio, duck audio, and more. You can update your shared instance early in your app lifecycle if you would like to ensure all Rive audio plays with the correct settings.

IOS

Copy

Ask AI

    // Example: Ignore the silent switch, and mix with other audio
    let category: AVAudioSession.Category = .playback
    let options: AVAudioSession.CategoryOptions = [.mixWithOthers]
    AVAudioSession.sharedInstance().setCategory(category, options: options)
    

[​

](#setting-volume)

Setting Volume
----------------------------------------

An artboard is capable of setting its volume. A parent artboard will set the volume of all nested artboards; however, setting a nested artboard’s volume will **not** update the parent’s volume.

IOS

Copy

Ask AI

    // Set the current artboard's volume to 50%
    let viewModel = RiveViewModel(fileName: "my_rive_file")
    viewModel.riveModel?.volume = 0.5


Logging
=======

Some Rive runtimes include logging capabilities to help with debugging. These logs are _only_ for debugging purposes; nothing is sent over the network, and no personally identifiable information (PII) is logged. The table below showcases the runtimes that support logging.

*   Apple

### 

[​

](#swift)

Swift

Copy

Ask AI

    RiveLogger.isEnabled = true // Enable logging; false by default
    RiveLogger.levels = [.debug] // Filter logs; all by default
    RiveLogger.categories = [.viewModel] // Filter categories; all by default
    RiveLogger.isVerbose = true // Include verbose logs; false by default
    

### 

[​

](#levels)

Levels

Logs will be logged at various levels, which are similar to those of `OSLogType` . These levels can be used to additionally filter logs to be logged at certain levels only. Available levels are:

*   Debug: most commonly used, to aid with debugging
*   Info: logs that provide additional information
*   Default: the default log level; however, many logs are `debug` level
*   Error: used when an error occurs
*   Fault: used when a critical (fatal) error occurs

### 

[​

](#categories)

Categories

Logs are split by categories; individual portions of the runtime are split into separate logs to support filtering. Available categories are:

*   State machine: operations that occur within an active state machine, such as receiving events
*   Artboard: operations that occur within an active artboard, such as advancing (verbose)
*   View model: operations that occur within a loaded `RiveViewModel` , such as triggering / setting inputs
*   Model: operations that occur within a loaded `RiveModel` , such as setting state machines / artboards
*   File: operations that occur within a loaded `RiveFile`, such as asset loading
*   View: operations that occur within a `RiveView`, such as player events (play / pause / stop / reset)

### 

[​

](#verbose-logs)

Verbose Logs

Certain logs are verbose, meaning they will stream logs consistently. Examples of these logs are view advances, and drawing validation. Verbose logs are disabled by default; see above for how to enable verbose logging.

Choose a Renderer

Choose a Renderer Overview
==========================

Specify a renderer to use at runtime.

Rive makes use of various different renderers depending on platform and runtime. We’re working towards unifying the default renderer used across all platforms/runtimes with the [Rive Renderer](https://rive.app/renderer).

Certain features, such as [Vector Feathering](https://rive.app/blog/introducing-vector-feathering), are only supported through the Rive Renderer. See our [Feature Support](/docs/feature-support) page for more information.

[​

](#renderer-options-and-default)

Renderer Options and Default
--------------------------------------------------------------------

You can opt-in to use a specific renderer, see [Specifying a Renderer](#specifying-a-renderer). The table below outlines the available, and default, renderers for Rive’s runtimes:

Runtime

Default Renderer

Options

Android

Rive

Rive / Canvas / Skia (removed as of v10.0.0)

Apple

Rive

Rive / Core Graphics / Skia (deprecated in v6.0.0)

React Native

Rive

See Apple and Android

Web (Canvas)

Canvas2D

Canvas2D

Web (WebGL)

Skia

Skia

Web (WebGL2)

Rive

Rive

Flutter

Skia (other), Impeller (iOS)

Skia / Impeller

### 

[​

](#note-on-rendering-in-flutter)

Note on Rendering in Flutter

Starting in Flutter `v3.10`, [Impeller](https://docs.flutter.dev/perf/impeller) has replaced [Skia](https://skia.org/) to become the default renderer for apps on iOS platforms and may continue to be the default on future platforms over time. As such, there is a possibility of rendering and [performance](https://github.com/flutter/flutter/issues/134432) discrepancies when using the Rive Flutter runtime with platforms that use the Impeller renderer that may not have surfaced before. If you encounter any visual or performance errors at runtime compared to expected behavior in the Rive editor, we recommend trying the following steps to triage:

1.  Try running the Flutter app with the `--no-enable-impeller` flag to use the Skia renderer. If the visual discrepancy does not show when using Skia, it may be a rendering bug on Impeller. However, before raising a bug with the Flutter team, try the second point below👇

Copy

Ask AI

    flutter run --no-enable-impeller
    

2.  Try running the Flutter app on the latest `master` channel. It is possible that visual bugs may be resolved on the latest Flutter commits, but not yet released in the `beta` or `stable` channel.
3.  If you are still seeing visual discrepancies with just the Impeller renderer on the latest master branch, we recommend raising a detailed issue to the [Flutter](https://github.com/flutter/flutter) Github repo with a reproducible example, and other relevant details that can help the team debug any possible issues that may be present.

[​

](#rive-renderer)

Rive Renderer
--------------------------------------

The [Rive Renderer](https://rive.app/renderer) is now available on Android and Apple runtimes. See [Specifying a Renderer](#specifying-a-renderer) to set it as your preferred renderer. While it’s ready for testing and your feedback is highly valued during this phase, we advise exercising caution before considering it for production builds. You may encounter compatibility issues with certain devices. Please reach out to us on Discord or through our Support Channel. Your collaboration helps us refine and enhance the Rive Renderer to make it more robust and reliable for broader applications. Thank you for being a part of this exciting journey!

*   Apple
*   Android
*   Web(JS)
*   React Native

[​

](#starting-version)

Starting Version
--------------------------------------------

The Rive Renderer was made the default renderer in Apple runtimes starting at **v6.0.0**, however, we recommend installing the latest version of the dependency to get the latest updates. See the [CHANGELOG](https://github.com/rive-app/rive-ios/blob/main/CHANGELOG.md) for details on the latest versions.

### 

[​

](#performance)

Performance

The Rive Renderer will shine best on Apple runtimes in memory usage as an animation plays out, in comparison to previous default renderers.With UIKit, you’ll be able to see the best performance differences by drawing multiple times on a single `RiveView`, rather than creating multiple instances of `RiveView`s, or multiple `RiveViewModel`s.**Example:** See this [stress test example](https://github.com/rive-app/rive-ios/blob/main/Example-iOS/Source/Examples/Storyboard/StressTest.swift) to see how you can override the drawing function on `RiveView` to draw multiple times on the same view, with each graphic at an offset. You can switch out the renderer with the above config and test out the performance for yourself!

[​

](#specifying-a-renderer)

Specifying a Renderer
------------------------------------------------------

See below for runtime instructions to enable a specific renderer.

*   Apple
*   Android
*   Web(JS)
*   React Native

[​

](#getting-started)

Getting Started
------------------------------------------

Options: `Rive (default) / Core Graphics / Skia (deprecated in v6.0.0)`Below are some notes on configuring the renderer in UIKit and SwiftUI.

### 

[​

](#uikit)

UIKit

Set the global renderer type during your application launch:

Copy

Ask AI

    @UIApplicationMain
    class AppDelegate: UIResponder, UIApplicationDelegate {
    
        func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
            // Override point for customization after application launch.
            RenderContextManager.shared().defaultRenderer = RendererType.riveRenderer
            return true
        }
    
        ...
    }
    

### 

[​

](#swiftui)

SwiftUI

New SwiftUI applications launch with the `App` protocol, but you can still add `UIApplicationDelegate` functionality.

#### 

[​

](#ios)

iOS

Create a new file and class called `AppDelegate` as such, including a line to set the `defaultRenderer` to `RendererType.riveRenderer`:

Copy

Ask AI

    import UIKit
    import Foundation
    import RiveRuntime
    
    class AppDelegate: NSObject, UIApplicationDelegate {
        func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
            RenderContextManager.shared().defaultRenderer = RendererType.riveRenderer
            return true
        }
    }
    

Next, at the entry point of your application, use `UIApplicationDelegateAdaptor` to set the `AppDelegate` created above for the application delegate.

Copy

Ask AI

    @main
    struct MyRiveRendererApp: App {
        @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
        
        var body: some Scene {
            WindowGroup {
                ContentView()
            }
        }
    }
    

#### 

[​

](#macos)

macOS

Create a new file and class called `AppDelegate` as such, including a line to set the `defaultRenderer` to `RendererType.riveRenderer`:

Copy

Ask AI

    import Foundation
    import RiveRuntime
    
    class AppDelegate: NSObject, NSApplicationDelegate {
        func application(_ application: NSApplication, applicationDidFinishLaunching notification: Notification) -> Bool {
            RenderContextManager.shared().defaultRenderer = RendererType.riveRenderer
            return true
    

Next, at the entry point of your application, use `UIApplicationDelegateAdaptor` to set the `AppDelegate` created above for the application delegate.

Copy

Ask AI

    @main
    struct MyRiveRendererApp: App {
        @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
        
        var body: some Scene {
            WindowGroup {
                ContentView()
            }
        }
    }

Advanced Topics

Format
======

[​

](#runtime-format)

Runtime Format
----------------------------------------

The Rive editor exports your project as a .riv file for consumption by the Rive runtimes. This is a binary representation of your Artboards, Shapes, Animations, State Machines, etc. This is the file that Rive’s runtimes read to display your content in an application, game, website, etc. The format was designed to provide a balance of quick load times, small file sizes, and flexibility with regards to future changes/addition of features.

### 

[​

](#binary-types)

Binary Types

A binary reader for Rive runtime files needs to be able to read these data types from the stream.

Byte order is little endian.

Type

Description

variable unsigned integer

LEB128 variable encoded unsigned integer (abbreviated to varuint going forward)

unsigned integer

4 byte unsigned integer

string

unsigned integer followed by utf-8 encoded byte array of provided length

float

32 bit floating point number encoded in 4 byte IEEE 754

Reference Binary Readers  
[Dart](https://github.com/rive-app/rive-flutter/blob/master/lib/src/utilities/binary_buffer/binary_reader.dart) [C++ Reader](https://github.com/rive-app/rive-cpp/blob/master/src/core/binary_reader.cpp) [C++ Decoder](https://github.com/rive-app/rive-cpp/blob/master/include/core/reader.h)

### 

[​

](#header)

Header

The header is the first thing written into the file and provides basic information for the runtime to verify that it can read this file. A ToC (table of contents/field definition) is provided which allows the runtime to understand how it can skip over properties and objects it may not understand. This is part of what makes the format resilient to future changes/feature additions to the editor. An older runtime can at least attempt to load an older file and display it without the objects and properties it doesn’t understand.

Value

Type

Fingerprint

4 bytes

Major Version

varuint

Minor Version

varuint

File ID

varuint

ToC

byte aligned bit array

**Fingerprint** The file fingerprint just lets the importer quickly sanity check that it’s actually looking at a file exported by Rive. This is 4 bytes representing the utf8/ascii “RIVE”. In a hex editor this looks like.

0x52 0x49 0x56 0x45/“RIVE”

**Major Version** Runtimes are compatible with only a single Major Rive export format version. The current major format is 7. If a 7 runtime encounters a 6 file, it will immediately error and not attempt to read any further content as the format is understood to be fundamentally different. This is provided as a last resort tool for Rive to fundamentally change its export format if it needs to. We try very hard to do this as rarely as possible. We recently needed to bump from 6 to 7 to add support for the State Machine, but in doing so we changed the format to be more resilient to such changes in the future. The editor currently supports exporting both major version 6 and major version 7 files, however, files exported with major version 6 will not include State Machine support.

Major versions are not cross-compatible. A major version 6 runtime cannot read major version 7 files. Similarly, a major version 7 files cannot read a major version 6 file.

**Minor Version** Minor version changes are compatible with each other provided the major version is the same. However, certain newer features may not be available if the runtime is of a different minor version. For example, major version 7 introduces the State Machine. We’re working on adding new state types to the State Machine. A version 7.0 runtime may not be able to load all the states exported in a 7.1 file. However, the runtime will still be able to play the state machine, it’ll simply not be able to do anything when it transitions to states it doesn’t understand. Example Version Compatibility

Runtime Version

File Version

Compatibility

6.1

6.0

Yes

6.1

6.2

Yes

6.1

7.0

No

7.0

6.1

No

7.0

7.1

Yes

#### 

[​

](#file-id)

File ID

This is a unique identifier for the file that in the future will be able to be used to distinguish the file by our API. The API isn’t defined yet, but some of the planned features include re-exporting a newer version of the file on demand, getting details of the file, etc. For now this can be used to verify which file this export was generated from.

#### 

[​

](#toc)

ToC

The Table of Contents section of the header is a list of the properties in the file along with their backing type. This allows the runtime to read past properties it wishes to skip or doesn’t understand. It does this by providing the backing type for each property ID.

#### 

[​

](#field-types)

Field Types

There are 5 fundamental backing types but they are serialized in 4 different ways. Knowing how the type is serialized allows the runtime to know how to read it in. Even if it reads the wrong value or interprets it incorrectly, the important aspect is being able to read past it so the rest of the file can be read in safely. For example, a boolean can be read as an unsigned integer as the backing type and serializer is compatible. Even though reading the boolean as an integer will not provide the valid value for the property, the runtime can still just read past it.

#### 

[​

](#toc-data)

ToC Data

The list of known properties is serialized as a sequence of variable unsigned integers with a 0 terminator. A valid property key is distinguished by a non-zero unsigned integer id/key. Following the properties is a bit array which is composed of the read property count / 4 bytes. Every property gets 2 bits to define which backing type deserializer can be used to read past it.

The intention here is to provide the known property type keys and their backing type, such that if the property type is unknown, the reader can read the entirety of the value without under/over running the buffer.

Backing Type

2 bit value

Uint/Bool

0

String

1

Float

2

Color

3

As an example, if there were a file with three known property types (property 12 a uint value, property 16 a string value, and 6 a bool value) the exporter would serialize data as follows: varuint: 12 varuint: 16 varuint: 6 varuint: 0 2 bits: 0 2 bits: 1 2 bits: 0

Reference ToC Deserializers [Flutter](https://github.com/rive-app/rive-flutter/blob/bbee63bb6c791dcabd0cd9d9788ca7ec4783fddb/lib/src/rive_core/runtime/runtime_header.dart#L43-L60) [C++](https://github.com/rive-app/rive-cpp/blob/4512406300b7333ba543cd87930e67a24c2fc715/include/runtime_header.hpp#L76-L104)

#### 

[​

](#baseline-properties)

Baseline properties

Rive won’t export properties that have been known to the system since the latest major version. We baseline when we shift new major versions as there will be no minor version that needs to read past newer properties. Newly introduced properties after the shift to the latest major will export as they are added and new minor versions are released.

[​

](#content)

Content
--------------------------

The rest of the file is simply a list of objects, each containing a list of their properties and values. An object is represented as a varuint type key. It is immediately followed by the list of properties. Properties are terminated with a 0 varuint. If a non 0 value is read, it is expected to the the type key for the property. If the runtime knows the type key, it will know the backing type and how to decode it. The bytes following the type key will be one of the binary types specified earlier. If it is unknown, it can determine from the ToC what the backing type is and read past it.

### 

[​

](#core)

Core

All objects and properties are defined in a set of files we call core defs for [Core Definitions](https://github.com/rive-app/rive-cpp/tree/master/dev/defs). These are defined in a series of JSON objects and help Rive generate serialization, deserialization, and animation property code. The C++ and Flutter runtimes both have helpers to read and generate a lot of the boilerplate code for these types.

#### 

[​

](#object)

Object

A core object is represented by its Core type key. For example, a Shape has [core type key 3](https://github.com/rive-app/rive-cpp/blob/4512406300b7333ba543cd87930e67a24c2fc715/dev/defs/shapes/shape.json#L4). Similarly you can see the generated code for the C++ runtime also [identifies a Shape with the same key](https://github.com/rive-app/rive-cpp/blob/4512406300b7333ba543cd87930e67a24c2fc715/include/generated/shapes/shape_base.hpp#L12).

#### 

[​

](#properties)

Properties

Properties are similarly represented by a Core type key. These are unique across all objects, so [property key 13](https://github.com/rive-app/rive-cpp/blob/4512406300b7333ba543cd87930e67a24c2fc715/dev/defs/node.json#L16) will always be the X value of a Node object, and it [matches in the runtime](https://github.com/rive-app/rive-cpp/blob/4512406300b7333ba543cd87930e67a24c2fc715/include/generated/node_base.hpp#L33). A Node’s X value is known to be a floating point value so when it is encountered [it will be decoded as such](https://github.com/rive-app/rive-cpp/blob/4512406300b7333ba543cd87930e67a24c2fc715/include/generated/node_base.hpp#L66-L68). Property key 0 is reserved as a null terminator (meaning we are done reading properties for the current object).

### 

[​

](#example-serialized-object)

Example Serialized Object

Data

Type/Size

Description

2

varuint

object of type 2 (Node)

13

varuint

X property for the Node

100.0

4 byte float

the X value for the Node

14

varuint

Y property for the Node

22.0

4 byte float

the Y value for the Node

0

varuint

Null terminator. Done reading properties and have completed reading Node.

### 

[​

](#context)

Context

Objects are always provided in context of each other. A Shape will always be provided after an Artboard. The Node’s artboard can always be determined by finding the latest read Artboard. This concept is used extensively to provide the context for objects that require it. Another example, a KeyFrame will always be provided after a LinearAnimation, meaning you can always determine which LinearAnimation a KeyFrame belongs to by simply tracking that last read LinearAnimation.

### 

[​

](#hierarchy)

Hierarchy

Objects inside the Artboard can be parented to other objects in the Artboard. This mapping is more complex and requires identifiers to find the parent. The identifiers are provided as a [core def property](https://github.com/rive-app/rive-cpp/blob/4512406300b7333ba543cd87930e67a24c2fc715/dev/defs/component.json#L28-L38). The value is always an unsigned integer representing the index within the Artboard of the ContainerComponent derived object that makes a valid parent.

For specifics around import context, you can review the ImportStack pattern used in the File reader. [Dart](https://github.com/rive-app/rive-flutter/blob/bbee63bb6c791dcabd0cd9d9788ca7ec4783fddb/lib/src/rive_file.dart#L101) [C++](https://github.com/rive-app/rive-cpp/blob/4512406300b7333ba543cd87930e67a24c2fc715/src/file.cpp#L137)



