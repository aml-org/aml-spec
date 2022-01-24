---
order: 2
---

# AML Dialects 1.0

AML Dialect defines a set of constraints over a RDF data-model composed by a graph of nodes connected by properties.

In this data-model, all node types and properties have associated terms that must have been defined in a AML Vocabulary.
Additionally, the AML Dialect also defines a mapping of this nodes over a set of modular documents (including partial definitions encoded in fragments and libraries of reusable components), that encode a mapping function capable of transforming document instances of the dialect encoded in YAML or JSON documents into RDF graphs encoded in JSON-LD documents.

An AML Dialect processor must accept this set of constraints and the projection over the modular documents and produce a parsing logic for the mapping function according to the syntactical rules defined in this specification.

## Dialect declaration

Dialect documents are declared using the `#%Dialect 1.0` header. Documents must provide a name for the dialect and a version number, using the `dialect` and `version` properties, respectively.

``` yaml
#%Dialect 1.0

dialect: Validation Profile
version: “1.0”
```

This information will be used to define the required declaration header for the document  instances of the new dialect.
In this example, dialect document instances must use the following document declaration header:

``` yaml
#%Validation Profile 1.0
```
The AML processor must have loaded the dialect definition in advance for the processor to be able to process the document instances.
To solve this problem, authors of document instances can optionally provide information about the location of the dialect definition to processors, linking it directly in the header of the document instance:

```yaml
#%Validation Profile 1.0 | <http://example.org/dialects/validation_profile>
```
When encoding dialect document instances using JSON syntax, is not possible to use headers as it is the case in dialect document instances encoded using YAML syntax. In this case, a `$dialect` linking directive can be used to declare the dialect for the document instance:

```json
{
  "$dialect": "Validation Profile 1.0"
}
```

## Using vocabularies

Dialects provide a mapping from vocabulary terms to the structure of a graph of data nodes. The `uses` property can establish this mapping by importing vocabularies in the dialect document:

``` yaml
uses:
  validation: validation.aml
```
Class terms and property terms from the vocabulary can then be referenced using the alias declared in the `vocabularies` property.

In the definition of a dialect, the `external` property can also explicitly reference external vocabularies, as defined in the AML Vocabulary spec. For example we could use Schema.org as an external vocabulary:


``` yaml
external:
  schema-org: http://schema.org/
```

## Node mappings

The property `nodeMappings` introduces the declaration of all the nodes in the model.
The nodes describe the mapping of vocabulary terms to the type of the node and its properties, as well as the constraints associated with each node.

Nodes are declared as a map from node names to node definitions.

The type of each node must be defined by the `classTerm` property.
Each node has also an associated `mapping` of node properties, defined by a label and a property mapping definition.

The following example defines a node mapping:

``` yaml
nodeMappings:

  profileNode:
    classTerm: validation.Profile
    mapping:
      profile:
        propertyTerm: schema-org.name
      description:
        propertyTerm: schema-org.description
```

In this case, we declare a new type of node in the model `profileNode` and we associate the class term `validation.Profile` with the type of node. The mapping of properties include two properties: `profile` mapped to the property term; `schema-org.name` and `description` mapped to `schema-org.description`.

The meaning of this mapping can be provided using closed world semantics via [W3C SHACL](https://www.w3.org/TR/shacl/) and defining a data shape constraint over the model data graph for the mapping we have just described:

```turtle
base:profileNode rdf:type shacl:NodeShape ;
  sh:targetClass validation:Profile ;
  sh:property base:profileNode/property/profile ;
  sh:property base:profileNode/property/description .

base:profileNode/property/profile sh:path schema-org:name .

base:profileNode/property/description sh:path schema-org:description .
```

Once this node is mapped to a document instance, it can be used to encode information about a profile, using the labels for the properties declared in the mapping:

``` yaml
#%Validation Profile 1.0

profile: OpenAPI
description: a test validation profile for AMF
```

When parsed, this document will generate the following RDF data graph:

```turtle
[
  rdfs:type validation:Profile ;
  schema-org:name "OpenAPI" ;
  schema-org.description "a test validation profile for AMF"
]
```

## Property mappings

A property can be constrained over instances of the model when declaring the property mapping of a data node.

| Property | Description | SHACL semantics |
|-------------|-------------|----------------|
| range       | allowed data type for the objects of the property | shacl:datatype |
| mandatory   | the property must be present in the node, default false | shacl:minCount 1 |
| pattern     | a regular expression that must match the value of the property | shacl:pattern |
| minimum     | minimum value for the property | shacl:minInclusive |
| maximum     | maximum value for the property | shacl:maxInclusive |
| enum        | closed set of values this property value must belong to | shacl:in |
| allowMultiple | multiple objects can be used in the value of this property, default false | remove shacl:minCount |

Some other properties in the property mapping can be used to define different ways of connecting the information in the document instance:

| Property | Description |
|-------------|-----------------|
| sorted  | Indicates that the values of the property must be stored preserving the declaration order |
| mapKey | declares a key nesting with the range node (see [Nesting by key](#mapping-only-the-key))|
| mapValue | declares a value nesting with the range node (see [Nesting by key value](#mapping-both-key-and-value))|

Finally, some properties can be used to allow users to work explicitly with unions of nodes:

| Property | Description |
|-------------|-----------------|
| typeDiscriminator | mapping from values to vocabulary classes used to disambiguate the type of node |
| typeDiscriminatorName | name of the property used to declare the value of the discriminator |


For example, the following property mapping will be translated into the SHACL constraint shape shown below:


``` yaml
nodeMappings:

  profileNode:
    classTerm: validation.Profile
    mapping:
      profile:
        propertyTerm: schema-org.name
        mandatory: true
        pattern: [a-z]+[A-Za-z]*
```

SHACL constraint shape:

``` turtle
base:profileNode rdf:type shacl:NodeShape ;
  sh:targetClass validation:Profile ;
  sh:property base:profileNode/property/profile .

base:profileNode/property/profile sh:path schema-org:name ;
  sh:minCount 1 ;
  sh:pattern "[a-z]+[A-Za-z]*" .
```

## Literal mappings

Property mappings can map literal `propertyTerms` from a vocabulary to scalar values in properties of the AST nodes in the document instance.

These mappings might have scalar data type in the mapping that will identify the correspondent XSD type associated to the mapping.

The list of valid literal mapping values and the associated  XSD data type can be found in the following table:

| Literal mapping | Data type |
|----------------------|---------------|
| string  | xsd:string |
| integer | xsd:integer |
| boolean | xsd:boolean |
| float | xsd:float |
| decimal | xsd:decimal |
| double | xsd:double |
| duration | xsd:duration |
| dateTime | xsd:dateTime |
| time | xsd:time |
| date | xsd:date |
| anyUri | xsd:anyUri |
| uri | xsd:anyUri |
| anyType | xsd:anyType |
| any  | xsd:anytype

An additional custom type is also available:

| Literal mapping | Custom data type | Description |
|----------------------|-------------------------|----------------|
| number  | shapes:number  | Any numeric data type |

Using literal ranges in property mappings will introduce the corresponding SHACL constraint that will be used by the AML processor to validate the parsed document instance graph.

## Data node mappings

Data node mappings can be connected to describe the full shape of the expected data model graph. This set of connected nodes also describe at the same time the full structure of the dialect document instance, understanding the property mappings defined in the dialect as a mapping function of the tree of AST nodes in the document instance over the generated output graph.

Nodes can be connected using different syntactic styles to allow more expressivity in the design of the dialect syntax using some of the allowed properties in a `nodeMapping`.

### Simple node nesting

The simplest way of connecting node mappings is by specifying the reference of another node in the `range` property of the parent node:

``` yaml
nodeMappings:

  shapeValidationNode:
    classTerm: validation.ShapeValidation
    mapping:
      name:
        propertyTerm: schema-org.name
        range: string
      message:
        propertyTerm: shacl.message
        range: string

  profileNode:
    classTerm: validation.Profile
    mapping:
      profile:
        propertyTerm: schema-org.name
      validations:
        propertyTerm: validation.validations
        range: shapeValidationNode
```

In the previous example, we have defined two node mappings: `profileNode` and `shapeValidationNode` and we have connected them through the `validations` property mapped to the `schema-org.name` property term.

With these mappings, dialect document instances will validate the following syntax:

``` yaml
#%Validation Profile 1.0

profile: My Profile
validations:
  name: my validation
  message: this is a validation
```

The previous document, when parsed, will generate the following RDF graph:

``` turtle
[
  rdfs:type validation:ShapeValidation ;
  schema-org:name "My Profile" ;
  validation:validations [

    rdfs:type validation:ShapeValidation
    schema-org:name "my validation" ;
    schema-org:message "this is a validation"

  ]
]
```

The SHACL semantics for this way of nesting of nodes are shown in the following translation of the dialect mappings:


``` turtle
base:profileNode rdf:type shacl:NodeShape ;
  sh:targetClass validation:Profile ;
  sh:property base:profileNode/property/profile ;
  sh:property base:profileNode/property/validations .

base:profileNode/property/profile sh:path schema-org:name ;
  sh:datatype xsd:string .

base:profileNode/property/validations sh:path validation:validations ;
  sh:maxCount 1 ;
  sh:node base:shapeValidationNode .

base:shapeValidationNode rdf:type shacl:NodeShape ;
  sh:targetClass validation:ShapeValidation ;
  sh:property base:shapeValidationNode/property/name ;
  sh:property base:shapeValidationNode/property/message .

base:shapeValidationNode/property/name sh:path schema-org:name ;
  sh:datatype xsd:string .

base:shapeValidationNode/property/message sh:path sh:message ;
  sh:datatype xsd:string .
```

More than one node mapping can be specified as the range of a property mapping. In this case any of those data node shapes will satisfy the parsing and the SHACL validation:

``` yaml
  profileNode:
    classTerm: validation.Profile
    mapping:
      validations:
        propertyTerm: validation.validations
        range:
          - shapeValidationNode
          - queryValidationNode
          - functionValidationNode
```

SHACL semantics:

``` turtle
base:profileNode rdf:type shacl:NodeShape ;
  sh:targetClass validation:Profile ;
  sh:property base:profileNode/property/validations .


base:profileNode/property/validations
  sh:or (
    [
      sh:maxCount 1 ;
      sh:path validation:validations ;
      sh:node base:shapeValidationNode ;
    ]
    [
      sh:maxCount 1 ;
      sh:path validation:validations ;
      sh:node base:queryValidationNode ;
    ]
    [
      sh:maxCount 1 ;
      sh:path validation:validations ;
      sh:node base:functionValidationNode ;
    ]
 ) .
```

### Multiple node nesting

Optionally, the designer of the dialect can allow multiple values instead of a single one in the range of the mapped property. This can be expressed using the `allowMultiple` property with a value of true.

``` yaml
nodeMappings:

  shapeValidationNode:
    classTerm: validation.ShapeValidation
    mapping:
      name:
        propertyTerm: schema-org.name
        range: string
      message:
        propertyTerm: shacl.message
        range: string

  profileNode:
    classTerm: validation.Profile
    mapping:
      profile:
        propertyTerm: schema-org.name
      validations:
        propertyTerm: validation.validations
        range: shapeValidationNode
        allowMultiple: true
```

With these mappings, dialect document instances will have to use the following syntax:

``` yaml
#%Validation Profile 1.0

profile: My Profile
validations:
  - name: my validation
    message: this is a validation
  - name: other validation
    message: this is another message
```
In the SHACL mapping, the generation of the `sh:maxCount 1` assertion would be omitted.
By default the nested nodes will be stored in the graph without any particular order. The `sorted` boolean property can be used to enforce ordering in the nested nodes. In this case the generated graph will keep the nodes in an ordered RDF collection.

## Nesting
### Introduction
In AML it is possible to represent a sequence of nodes as a map. This can be achieved by introducing an extra layer of nesting
between parent and child nodes. Take a look at the following examples:

**Dialect (without nesting)**
```yaml
ParentNodeMapping:
  mapping:
    name:
      range: string
    children:
      range: ChildNodeMapping
      allowMultiple: true

ChildrenNodeMapping:
  mapping:
    name:
      range: string
    favoriteColor:
      range: string
```

**Without nesting**
```yaml
name: parent
children:
  - name: child1
    favoriteColor: red
  - name: child2
    favoriteColor: blue
```

**With nesting key**
```yaml
name: parent
children:
  child1:
    favoriteColor: red
  child2:
    favoriteColor: blue
```

As it can be observed in the above example the `children` property used to have a sequence as its range which could be 
re-written as a map. This was done by introducing **new keys** associated with the `name` property of the child node. 
The `name` property will be known as the _key-mapped property mapping_ (formal definition coming shortly) since its value
is mapped from the keys of the extra nesting layer. 

For some cases it is possible to go a step further and not only define a _key-mapped property mapping_ but also to 
define a _value-mapped property mapping_. Take a look at the following example:

**Dialect (without nesting)**
```yaml
PaletteNodeMapping:
  mapping:
    name: 
      range: string
    colors:
      range: ColorNodeMapping
      allowMultiple: true

ColorNodeMapping:
  mapping:
    name:
      range: string
    code:
      range: string
```

**Without nesting**
```yaml
name: Color palette
colors:
  - name: red
    code: FF0000
  - name: blue
    code: 0000FF
```

**With nesting key and value**
```yaml
name: Color palette
colors:
  red: FF0000
  blue: 0000FF
```

In the first example, with nesting keys only, the value of the extra nesting layer was mapped to the rest of the node
mapping as any other node-node mapping pair. With node value mapping, the value of the extra nesting layer gets mapped to
another property mapping without having to specify the property mapping label like `name` or `code` for each color. Both 
the color `name` and `code` properties where mapped from the keys and values of the map.

### Feature definition
In AML it is possible to:
* Map **only the key** of a key-value entry to a property mapping value by its name
* Map **both key and value** of a key-value to a pair of property mappings values by their names

These changes are merely syntactical; neither the parsed graph for the dialect instance, nor the SHACL semantics for the
constraint are affected by nesting.

### Concepts definition
To add this extra nesting level it is necessary to have _two node mappings_ in the dialect definition in which _one is 
the range of some property mapping of the other_ (e.g. `PaletteNodeMapping` & `ColorNodeMapping`).

The mentioned node and property mappings are defined as follows: 

*Source node mapping*: is the node mapping responsible for parsing the dialect instance node higher in the nesting hierarchy (e.g. `PaletteNodeMapping`)

*Range node mapping*: is the node mapping responsible for parsing the dialect instance node lower in the nesting hierarchy (e.g. `ColorNodeMapping`)

*Source property mapping*: is the property mapping (in the _source node mapping_) that connects the _source node mapping_ and the _range node mapping_ via its range (e.g. `PalatteNodeMapping.colors`)

### How to include nesting in Dialect definitions
#### Mapping only the key
To map the key of a key-value entry in the dialect instance to the value of some property mapping in the 
_range node mapping_ it is necessary to define a `mapKey` facet in the _source property mapping_:

* `mapKey` selects the property mapping in the _range node mapping_ to map to the key by its _name_

The target property mapping of the `mapKey` facet is defined as the **key-mapped property mapping**.

##### Consideration case for unions
If the _range node mapping_ was a union node mapping it is required that either:
* Every union member provides a definition for the *key-mapped property mapping*.
* The `mapKey` facet defines a property mapping from each union member

It is also required that removing the label of the key-mapped property mapping does not introduce ambiguities (see [Selecting the appropriate member from a union when parsing a document instance](#Selecting the appropriate member from a union when parsing a document instance))

##### Examples
###### Example 1: simple definition
_Dialect with nesting_
```yaml
Source:
  mapping:
    sourceProperty:
      range: Range
      mapKey: keyProperty

Range:
  mapping:
    keyProperty:
      range: string
      mandatory: true
      unique: true
    propertyA:
      range: string
    propertyB:
      range: string
```

_With nesting_
```yaml
sourceProperty:
  valueOfKeyProperty:
    propertyA: valueOfPropertyA
    propertyB: valueOfPropertyB
```

As it can be seen in the dialect definition from the above example, there are two node mappings `Source` and `Range` being these the 
_source node mapping_ and _range node mapping_ respectfully. `Source` defines a property mapping `sourceProperty` (the _source property mapping_) whose 
range is `Range` and map key is `keyProperty`.

In the dialect instance, the value of the `sourceProperty` is a map containing only one entry with key `valueOfKeyProperty` and 
value another map (nested map). Since the `keyProperty` property mapping was marked as the map key of `sourceProperty`, the key 
`valueOfKeyProperty` will be set as the value of the `keyProperty` property mapping. For this same reason it will not be necessary to 
write explicitly the `keyProperty` name for it. On the other hand, the value of the mentioned key-value
entry (the nested map) contains the entries for the reminder property mappings `propertyA` and `propertyB`.

The below example shows how the dialect instance would look if no map key was defined for `sourceProperty`:

_Without nesting_:
```yaml
sourceProperty:
  keyProperty: valueOfKeyProperty
  propertyA: valueOfPropertyA
  propertyB: valueOfPropertyB
```

Notice that all the property mappings (`keyProperty`, `propertyA`, `propertyB`) from the range node mapping (`Range`) have the same nesting level.

###### Example 2: unions with same property mapping
_Dialect with nesting_
```yaml
Source:
  mapping:
    sourceProperty:
      range: UnionRange
      mapKey: keyProperty # defined in all members

UnionRange:
  union:
    - MemberA
    - MemberB
    - MemberC
MemberA:
  mapping:
    keyProperty:
      range: string
      mandatory: true
      unique: true
    propertyA:
      range: string
MemberB:
  mapping:
    keyProperty:
      range: string
      mandatory: true
      unique: true
    propertyB:
      range: string
MemberC:
  mapping:
    keyProperty:
      range: string
      mandatory: true
      unique: true
    propertyC:
      range: string
```

_With nesting_
```yaml
sourceProperty:
  nodeA: # MemberA.keyProperty
    propertyA: hello # MemberA.propertyA
  nodeB: # MemberB.keyProperty
    propertyB: hello # MemberB.propertyB
  nodeC: # MemberC.keyProperty
    propertyC: hello # MemberC.propertyC
```

###### Example #: unions with different property mappings
_Dialect with nesting_
```yaml
Source:
  mapping:
    sourceProperty:
      range: UnionRange
      mapKey: 
        MemberA: keyPropertyA
        MemberB: keyPropertyB
        MemberC: keyPropertyC
UnionRange:
  union:
    - MemberA
    - MemberB
    - MemberC
MemberA:
  mapping:
    keyPropertyA:
      range: string
      mandatory: true
      unique: true
    propertyA:
      range: string
MemberB:
  mapping:
    keyPropertyB:
      range: string
      mandatory: true
      unique: true
    propertyB:
      range: string
MemberC:
  mapping:
    keyPropertyC:
      range: string
      mandatory: true
      unique: true
    propertyC:
      range: string
```

_With nesting_
```yaml
sourceProperty:
  nodeA: # MemberA.keyPropertyA
    propertyA: hello # MemberA.propertyA
  nodeB: # MemberB.keyPropertyB
    propertyB: hello # MemberB.propertyB
  nodeC: # MemberC.keyPropertyC
    propertyC: hello # MemberC.propertyC
```

##### Validation of key mapping definitions
Failing to meet the following conditions will raise a **violation** in the _dialect definition_:
* Only property mappings with literal ranges can be defined as _key-mapped property mapping_

* For non-union _range node mappings_, the value of the `mapKey` facet should match some property mapping in the _range node mapping_ by either its name 
* For union _range node mappings_, the value of the `mapKey` facet should either:
    * Match some common property mapping in all union members
    * Define an _existing_ property mapping for each and every union member from the in the _range node mapping_ in a map with the syntax `UnionMember: propertyMappingFromUnionMember` 

* Removing the _key-mapped property_ mapping label does not introduce ambiguities in union member selection

#### Mapping both key and value
To map the value of a key-value entry in the dialect instance to the value of some property mapping in the 
_range node mapping_ the `mapValue` facet must be defined in the _source property mapping_ (having already defined a 
`mapKey` facet):

* `mapValue` selects the property mapping in the _range node mapping_ to map to the value by its _name_

The target property mapping of the `mapValue` facet is defined as the **value-mapped property mapping**

##### Consideration case for unions
It is not possible to define a value mapping when the _range node mapping_ is a union node mapping. 

##### Examples 
###### Example 1

Imagine you want to generate in the graph a list labels, with a `name` property for the label name and a `value` 
property for the value of the label.

You could declare the syntax in your dialect as a map of key-value pairs in the following way:

```yaml
nodeMappings:
  LabelNode:
    classTerm: myvocab.Label
    mapping:
      name:
        propertyTerm: myvocab.labelName
        range: string
      value:
        propertyTerm: myvocab.labelValue
        range: string
  TopLevelNode:
    classTerm: myvocab.TopLevel
    mapping:
      labels:
        propertyTerm: myvocab.labels
        range: LabelNode
        mapKey: name
        mapValue: value
```

Using this syntax a document for this dialect could declare a list of labels in the following way:


```yaml
labels:
  label1: a
  label2: b
```

The generated RDF graph will look like this:

```turtle
[
  rdf:type myvocab:TopLevel ;
  myvocab:labels [
    rdf:type myvocab.Label
    myvocab:labelName "label1" ;
    myvocab:labelValue "a"
  ] , [
    rdf:type myvocab.Label
    myvocab:labelName "label2" ;
    myvocab:labelValue "b"
  ]
]
```

##### Validation of nesting with value mapping
Failing to meet the following conditions will raise a **violation** in the _dialect definition_:
* Only property mappings with literal ranges can be defined as _value-mapped property mapping_ (`allowMultiple: true` is accepted)
* The `mapValue` facet can only be defined if `mapKey` is defined (and valid) as well
* The value of the `mapValue` facet should match some property mapping in the _range node mapping_ by its name
* The value of the `mapValue` facet cannot match the same property mapping as the `mapKey` facet
* Mandatory property mappings in the _range node mapping_ must be either _key-mapped_ or _value-mapped_ property mappings
* Union node mappings cannot be defined as _range node mappings_ with key-value nesting 

### Some considerations for nesting & further validations
* The range of the _source property mapping_ will allow multiple objects in its value (defaults to `allowMultiple: true`).
Setting the `allowMultiple` facet to `false` will result in a **violation** in the dialect definition. 
* When mapping both key and value, additional non-mandatory property mappings which are neither _key-mapped_ nor 
_value-mapped_ will not be parsed. This is valid behavior. Nevertheless these scenarios should result in a **warning** 
in the dialect definition to prevent undesired behaviors.
* _Value-mapped property mappings_ allow only scalar ranges. Other modeling alternatives are should be used when a 
map is needed as the range of a _value-mapped property mapping_, like extracting a new node mapping and using only
_key-mapped property mappings_. 
* Unions are allowed only when defining _key-mapped properties_. Unions allow to unify different node mapping structures
into a single one. When defining both _key-mapped_ and _value-mapped_ property mappings the structure for every value
of the _source property mapping_ shares the same structure `key:value` (since _value-mapped property mappings_ have literal
ranges).

## Unions

Unions are a mechanism for declaring a set of `nodeMappings` (literals not supported) that can be used in different 
parts of a dialect. Each of the node mappings in a union is called a **member** of that union.

Dialects support declaring two kinds of unions. These are:
* *Union range*: union set as the range of a property mapping
* *Union node*: union set as an independent node mapping

### Union range
To declare a _union range_ a non-empty array of `nodeMappings` members must be specified as the value for the of the 
`range` facet of a property mapping

For example:

```yaml
#%Dialect 1.0
dialect: Union Range
version: 1.0
nodeMappings:
  A:
    …
  B:
    …
  RootNode:
    mapping:
      allowMultiple: true
      unionProperty:
        propertyTerm: vocab.unionProp
        range: [ A, B ]
```

### Union node
To declare a _union node_ a non-empty array of `nodeMappings` members must be specified as the value for the of the 
`union` facet of a node mapping

For example:
```yaml
#%Dialect 1.0
dialect: Union Node
version: 1.0
nodeMappings:
  A:
    …
  B:
    …
  RootNode:
    union:
      - A
      - B
```

Union nodes cannot define additional property mappings

### Selecting the appropriate member from a union when parsing a document instance
The AML processor must be able to disambiguate the appropriate union member to parse when parsing a document instance. 
To achieve that disambiguation the AML processor requires *hints* to make the selection. Those hints can be obtained via 
two mechanisms:
* Implicitly using *Schema inference*
* Explicitly using *Type discriminators* 

#### Schema inference
In schema inference the AML processor automatically selects the appropriate union member based on hints provided by the 
schema represented by a node mapping.

It selects the union member for which the node in the document instance can be bound to its set of property mappings. 
This means the node in the document instance defined values for at least the mandatory properties of the union member, 
regardless if those values are valid or not.

If the ability to bind property mappings is satisfied for more than one union member this will be considered *ambiguous* 
and invalid.

To avoid ambiguity it is required that in the dialect definition:
* The set of property mapping **names** in each union member is not equal to any other union member's same set.

Failing to meet this condition will result in a violation because it introduces un-avoidable ambiguity (see example 4)
   
To avoid ambiguity it is recommended that in the dialect definition: 
* All members of a union define at least one mandatory property
* The set of mandatory property mappings **names** in each union member is not equal to any other union member's same 
set.

Failing to meet these conditions will result in warnings because it can introduce eventual ambiguity (see example 3)

*Note: only property mapping names are checked because ranges can be other sources of ambiguity*

Example 1: no ambiguity
```yaml
#%Dialect 1.0
dialect: Union Node
version: 1.0
nodeMappings:
  A:
    mapping:
      propertyA:
        range: string
        mandatory: true
      propertyX:
        range: string
        mandatory: true
  B:
    mapping:
      propertyB:
        range: string
        mandatory: true
      propertyX:
        range: string
        mandatory: true

  RootNode:
    union:
      - A
      - B
```

This node will be parsed as node A because only node A's property mappings can be bounded 
```yaml
propertyA: some value for property A
propertyX: some value for property X
```

Example 2: no ambiguity
```yaml
#%Dialect 1.0
dialect: Union Node
version: 1.0
nodeMappings:
  A:
    mapping:
      propertyA:
        range: string
        mandatory: true
      propertyX:
        range: string
        mandatory: true
  B:
    mapping:
      propertyB:
        range: string
        mandatory: false
      propertyX:
        range: string
        mandatory: true

  RootNode:
    union:
      - A
      - B
```

This node will be parsed as node A because only node A's property mappings can be bounded 
```yaml
propertyA: some value for property A
propertyX: some value for property X
```

This node will be parsed as node B because only node B's property mappings can be bounded
```yaml
propertyB: some value for property B
propertyX: some value for property X
```

This node will be parsed as node B because only node B's property mappings can be bounded (`propertyB` is optional while
 `propertyA` is mandatory)  
```yaml
propertyX: some value for property X
```

Example 3: eventual ambiguity
```yaml
#%Dialect 1.0
dialect: Union Node
version: 1.0
nodeMappings:
  A:
    mapping:
      propertyA:
        range: string
        mandatory: false
      propertyX:
        range: string
        mandatory: true
  B:
    mapping:
      propertyB:
        range: string
        mandatory: false
      propertyX:
        range: string
        mandatory: true

  RootNode:
    union:
      - A
      - B
```

This node will be parsed as node A because only node A's property mappings can be bounded 
```yaml
propertyA: some value for property A
propertyX: some value for property X
```

This node will be parsed as node B because only node B's property mappings can be bounded
```yaml
propertyB: some value for property B
propertyX: some value for property X
```

This node is ambiguous because both set of property mappings (from nodes A & B) can be bounded. Recall that both 
`propertyA` & `propertyB` are non mandatory so this node could be parsed as either node A or node B. 
```yaml
propertyX: some value for property X
```

Example 4: un-avoidable ambiguity
```yaml
#%Dialect 1.0
dialect: Union Node
version: 1.0
nodeMappings:
  A:
    mapping:
      propertyX:
        range: integer
        mandatory: true
  B:
    mapping:
      propertyX:
        range: string
        mandatory: true

  RootNode:
    union:
      - A
      - B
```

In this example ambiguity cannot be avoided by dialect definition. Recall that only property mapping names are checked for ambiguity.  


#### Type discriminators
Type discriminators are explicit hints defined by the dialect that tell the AML processor which union member to select

The dialect must define a special property as the `typeDiscriminatorName` and a series of *distinct* values that can 
be bound to such property. Each of those values must be listed under the `typeDiscriminator` facet and must define a 
1-to-1 correspondence with each of the union members.

Discriminator properties do not have semantics, their only purpose is to disambiguate between union members.

Discriminators can be defined for both **Union nodes** and **Union ranges**

Example using **Union nodes**:
```yaml
#%Dialect 1.0
dialect: Test Unions
version: 1.0

nodeMappings:
  A:
    ...
    mapping:
      text:
        propertyTerm: vocab.text
        range: string
  B:
    …
    mapping:
      text:
        propertyTerm: vocab.text
        range: string

  RootNode:
    union:
      - A
      - B  
    typeDiscriminatorName: kind
    typeDiscriminator:
      TypeA: A
      TypeB: B
```

This example will be parsed as node A because the value of the `kind` property marked as discriminator is `TypeA` which
corresponds with the A node as marked in the `typeDiscriminator` facet.
```yaml
text: Hello world
kind: TypeA
```

Example using **Union ranges**:
```yaml
#%Dialect 1.0
dialect: Test Unions
version: 1.0

nodeMappings:
  A:
    ...
    mapping:
      text:
        propertyTerm: vocab.text
        range: string
  B:
    …
    mapping:
      text:
        propertyTerm: vocab.text
        range: string

  RootNode:
    mapping:
      unionProperty:
        propertyTerm: vocab.unionProp
          range: [ A, B ]
          allowMultiple: true
          typeDiscriminatorName: kind
          typeDiscriminator:
            TypeA: A
            TypeB: B
```
In this case the first element of the `unionProperty` will be parsed as node A and the second as node B for the same 
reason as in the previous example.
```yaml
unionProperty:
  - text: This will be parsed as node A
    kind: TypeA
  - text: This will be parsed as node B
    kind: TypeB 
```

The rules for defining discriminators are following:
* Both `typeDiscriminator` and `typeDiscriminatorName` facets must be defined in conjunction with non-null values
* Both `typeDiscriminator` and `typeDiscriminatorName` can only be defined for **union nodes** or **union ranges**
* The values listed in the `typeDiscriminator` facet must be distinct and have a 1-to-1 correspondence with each union 
member
* The `typeDiscriminatorName` facet cannot define a type discriminator property which overrides any property mapping 
from any of the union members
* The `typeDiscriminatorName` facet cannot define a type discriminator property which overrides any type discriminator 
property from any of the union members


If a document instance defines as the value of the type discriminator property a value which is not included in the list
defined by the `typeDiscriminator` facet, that instance is invalid.

Invalid example:
```yaml
#%Dialect 1.0
dialect: Test Unions
version: 1.0

nodeMappings:
  A:
    ...
    mapping:
      text:
        propertyTerm: vocab.text
        range: string
  B:
    …
    mapping:
      text:
        propertyTerm: vocab.text
        range: string

  RootNode:
    union:
      - A
      - B  
    typeDiscriminatorName: kind
    typeDiscriminator:
      TypeA: A
      TypeB: B
```

This example is invalid because `TypeC` is not listed in the `typeDiscriminator` facet. 
```yaml
text: Hello world
kind: TypeC
```

*Note: the use of discriminators is recommended because they erase the posbility of ambiguity*

## Semantic Extensions

AML Dialect documents can be also be used to define "extension" that may be used to extend other "semantic documents" like any AML Dialects, Fragments or Modules or API Specifications.

### Defining a Semantic Extension
Semantic extensions are defined under the `extensions` key at the base of the document. Each YAML key is the name with which the extension is defined by and the value is a reference to a user-defined [Annotation Mapping](#annotation-mappings).

``` yaml
extensions:
  paginated: PaginationMapping
  deprecated: DeprecationMapping
```

The notation with which the semantic extension is written in the target document depends on the notation the document's specification defines to write custom user-extensions.

For example, given the following extensions:
```yaml
extensions:
  scraped-from: MovieInformationProviderMapping # Suppose this mapping is defined.
```

it can be used from an AML Dialect Instance like:
```yaml
#%Movie 1.0
title: The Lord of the Rings
director: Peter Jackson
(scraped-from):
  name: IMDB
  url: https://www.imdb.com/title/tt0120737/
```

## Annotation Mappings
Annotation Mappings are used to define the structure that an extension must have. These mappings contain the same fields as a [Property Mappings](#property-mappings) with the exception of **mapKey** and **mapValue**.

It also defines some fields of its own:
| Property | Value | Description |
|-------------|-------------|-----------------|
| domain | string | identifies the node type which may be extended by a semantic extension     |
| propertyTerm | string | URI used as predicate to link the extended node with the value described with the Annotation Mapping range  |


They are defined under the `annotationMappings` key in a YAML Map where the key is the name of the Annotation Mapping.

```yaml
annotationMappings:
  PaginationMapping:
    domain: apiContract.Response
    propertyTerm: apiContract.pagination
    range: integer # Like Node properties, it allows scalar ranges
    minimum: 0

  DeprecatedMapping:
    domain: apiContract.Endpoint
    propertyTerm: apiContract.deprecated
    range: Deprecated  # Like Node properties, it allows re-using defined Node mappings elsewhere.

nodeMappings:
  Deprecated:
    mappings:
      date:
        range: string
        mandatory: true
      reasion:
        range: string
        mandatory: true

```

**Note**: An AML processor MUST provide a mechanism with which document writers may extend their documents with semantic extensions. They may optionally provide a way for users to register their own semantic extensions.
## Document model mapping

To use the node mappings and constraints defined in the dialect to support new types of documents, we must map the node mappings to the different types of modular documents supported by AML:

- **Documents**: stand-alone documents that can encode a main element of the domain and declare auxiliary elements that then can be referenced in the document
- **Modules**: libraries containing sets of declarations of reusable definitions that can be referenced from other types of documents
- **Fragments**: non-standalone documents encoding a single element that can be included in other types of documents

The mapping in a dialect is achieved through the `documents` property. The value of this property is a mapping with 3 possible keys:

| Property | Description |
| ---      | ---         |
| root | nodes that can be declared and encoded in the root document for the dialect |
| module   | nodes that can be declared in a library for the dialect |
| fragments | nodes that can be encoded into fragments for the dialect |

### Defining the root document mapping

Root documents can encode one type of node, and declare many types of nodes using the following properties:

| Property | Description |
| ---      | ---         |
| encodes | main node mapping that will be encoded at the root level of the dialect document |
| declares | mapping from declaration key to the type of nodes that can be declared for that key |

Consider the following example mapping:

``` yaml
nodeMappings:

  shapeValidationNode:
    classTerm: validation.ShapeValidation
    mapping:
      name:
        propertyTerm: schema-org.name
        range: string
      message:
        propertyTerm: shacl.message
        range: string

  profileNode:
    classTerm: validation.Profile
    mapping:
      profile:
        propertyTerm: schema-org.name
      validations:
        propertyTerm: validation.validations
        range: shapeValidationNode
        allowMultiple: true

documents:

  root:
    encodes: profileNode
    declares:
      localValidations: shapeValidationNode
```

We are stating that the modular documents for this dialect will encode a `profileNode` mapping and will be able to declare `shapeValidationNodes` introduced by the property `localValidations`.

For example:


``` yaml
#%Validation Profile 1.0

# the declarations here
localValidations:
  validation1:
    name: my validation
    message: this is a message

# the main encoded element
profile: My Profile
validations:
  - validation1 # using the declaration
```

### Defining module mappings

Modules can declare multiple elements that then can be reused from other documents using the library.

The module mapping can be defined using the following properties:

| Property | Description |
| ---      | ---         |
| declares | mapping from declaration key to the type of nodes that can be declared for that key |

Consider the following example mapping:

``` yaml
nodeMappings:

  shapeValidationNode:
    classTerm: validation.ShapeValidation
    mapping:
      name:
        propertyTerm: schema-org.name
        range: string
      message:
        propertyTerm: shacl.message
        range: string

  profileNode:
    classTerm: validation.Profile
    mapping:
      profile:
        propertyTerm: schema-org.name
      validations:
        propertyTerm: validation.validations
        range: shapeValidationNode
        allowMultiple: true

documents:

  root:
    encodes: profileNode
    declares:
      localValidations: shapeValidationNode

  module:
    declares:
      libraryValidations: shapeValidationNode
```

We have expanded the documents mapping to support libraries of validations, declared using the property `libraryValidatons`.

For example:

``` yaml
#%Library / Validation Profile 1.0

# Starting the declarations here
libraryValidations:

  validation1:
    name: my validation
    message: this is a message

  validation2:
    name: other validation
    message: this is the other message
```

In the declaration of the AML dialect, we need to provide to the dialect processor the identifier of the dialect. The dialect processor can then determine how to parse the document.

From the main dialect document we can use the library using a library alias reference introduced with the `uses` keyword or through ` $ref` link:

``` yaml
#%Validation Profile 1.0

# using the library
uses:
  vals: validations_library.yaml


# the main encoded element
profile: My Profile
validations:
  - vals.validation1 # using the declaration
```

### Defining fragment mappings

Fragments are not-stand-alone documents that need to be included in other documents to be re-used.

We can define which types of fragments are supported in our dialect using the `fragments` property and the nested `encodes` property.

The value of this property is a mapping from fragment header identifier to node mapping that the fragment must satisfy:

| Property | Description |
| ---      | ---         |
| encodes | mapping from fragment header identifier to the type of nodes that can be encoded in that fragment |


Consider the following mapping:

``` yaml
nodeMappings:

  shapeValidationNode:
    classTerm: validation.ShapeValidation
    mapping:
      name:
        propertyTerm: schema-org.name
        range: string
      message:
        propertyTerm: shacl.message
        range: string

  profileNode:
    classTerm: validation.Profile
    mapping:
      profile:
        propertyTerm: schema-org.name
      validations:
        propertyTerm: validation.validations
        range: shapeValidationNode
        allowMultiple: true

documents:

  root:
    encodes: profileNode
    declares:
      localValidations: shapeValidationNode

  fragments:
    encodes:
      Validation: shapeValidationNode
```

With this mapping, we can define a fragment for the dialect with the following shape validation:

``` yaml
#%Validation / Validation Profile 1.0

# the encoded validation
name: my validation
message: this is a message
```

This fragment can be used from the main dialect document through a `!include` link:


``` yaml
#%Validation Profile 1.0

# the main encoded element
profile: My Profile
validations:
  - !include validation_fragment.yaml
```

### Document model mapping options

The document model mapping can be customized with the following options inside the `options` property. These apply to all the defined documents in the document mapping.

| Property | Description | Values |
| ---      | ---         | ---    |
| `selfEncoded`       | Indicates if the base unit URI is the same as the URI of the encoded node in the unit        | `true`: same URI <br> `false` (default): different URIs |
| `declarationsPath`  | Location for parsed declarations IDs                                                         | string. <br> Example: `some/path/to/declarations` |
| `keyProperty`       | Indicates if the dialect to parse a dialect instance is identified by a property or a header | `true`: identified by property `DIALECT_NAME: DIALECT_VERSION` <br> `false` (default): identified by header `#%DIALECT_NAME DIALECT_VERSION` |
| `referenceStyle`    | Determines the style for inclusions between the defined documents in the document mapping    | `RamlStyle` (default): inclusions using `!include` tag <br> `JsonSchemaStyle` inclusions using `$ref` map |

## Dynamic composition of documents

Sometimes is not possible to know in advance which kind of documents are going to be composed, or we want to provide an expansion point in our dialect where other types of documents from external dialects are linked.

We can achieve this declaring dynamic property mappings, using the special value `anyNode` as the value of the `range` property in the mapping.

Consider the following example:

```yaml
#%Dialect 1.0
dialect: Test Dynamic Node
version: 1.0

external:
  v: http://test.com/v#

nodeMappings:
  RootNode:
    classTerm: v.Root
    mapping:
      dynamic:
        propertyTerm: v.dynamic
        range: anyNode

documents:
  root:
    encodes: RootNode
```

In this case the range of the `dynamic` property mapping in the `RootNode` has been declared to be `anyNode` that means that any valid node can be inserted in that position of the AST of the document.

For example, any fragment can be included:

```yaml
#%Test Dynamic Node 1.0

dynamic: !include external_fragment.yaml
```

In order for the AML processor to be able to parse the external fragments the document instance must include the explicit link to the dialect in the document header.

Dynamic nodes can also be declared inline nested under the dynamic nodes.
In this case, in order for the AML processor to be able to parse the nested AST, the `nodeMapping` in the external dialect must be declared in the top level node of the dynamic tree using the `$dialect` linking directive. Notice that the reference must be a JSON pointer to the node mapping in the external dialect, not only to the dialect document.

For example:

```yaml
#%Test Dynamic Node 1.0

dynamic:
  $dialect: external_dialect.yaml#/declarations/TopLevelNode
  label: this is declared in ‘TopLevelNode’ of ‘external_dialect.yaml’
```

## ID/URI generation and customization

By default every AML processor must generate automatic URIs identifying every node in the parsed information graph.
URIs will be generated as hash URIs based on the location of the parsed node in the document AST.

The root node of the document will be identified by the `#/` fragment. Declarations will be introduced by fragments using the declaration value defined in the document mapping.

Node mappings declarations in a dialect document will be defined under the `#/declarations` fragment path.

The final ID/URI associated to a node in the parsed graph can be controlled using the `$id` directive. The value of `$id` can be a relative or absolute URI that will be used to identify the parsed node for that AST node in the output graph.

## Overriding the base of an ID/URI

The different ID/URI generation mechanisms can be combined with the `$base` directive to override the base of an ID/URI.

We define the **base of a URI** as
> The beginning part of a URI until the first (inclusive) '#' character or else the first '/' (inclusive) character (excluding the 
> ones from the protocol) if no '#' character is defined

The `$base` directive can be used *from the document* to replace the base (as defined above) by the value defined by 
such directive.

The `$base` directive replaces the base for any ID, regardless if it was set explicitly by some mechanisms such as 
`idTemplate` or the `$id` directive, or if it was automatically generated by the AML processor.

**Example 1: idTemplate base delimited by '#'**

Dialect:
```yaml
SomeNode:
    mapping:
      a:
        mandatory: true
        range: string
    idTemplate: "http://a.ml/resources#{a}" 
```

Document _without_ base: 
```yaml
a: my-resource
```
parses to:
```json
{ "@id": "http://a.ml/resources#my-resource" }
```

Document _with_ base: 
```yaml
a: my-resource
$base: http://overriden.org/some/path/
```
parses to:
```json
{ "@id": "http://overriden.org/some/path/my-resource" }
```

**Example 2: idTemplate base delimited by '/'**

Dialect:
```yaml
SomeNode:
    mapping:
      a:
        mandatory: true
        range: string
    idTemplate: "http://a.ml/resources/{a}" ## first '/' after a.ml
```

Document _without_ base: 
```yaml
a: my-resource
```
parses to:
```json
{ "@id": "http://a.ml/resources/my-resource" }
```

Document _with_ base: 
```yaml
a: my-resource
$base: http://overriden.org/some/path/
```
parses to:
```json
{ "@id": "http://overriden.org/some/path/resources/my-resource" }
```

**Example 3: $id base delimited by '#'**

Document _without_ base: 
```yaml
some-property: some-value
$id: http://a.ml/resources#my-node
```
parses to:
```json
{ "@id": "http://a.ml/resources#my-node" }
```

Document _with_ base: 
```yaml
some-property: some-value
$id: http://a.ml/v1/resources#my-node
$base: http://a.ml/v2/resources#
```
parses to:
```json
{ "@id": "http://a.ml/v2/resources#my-node" }
```

#### $base for idTemplate
Defining `idTemaplate` in the dialect might generate some unwanted situations when overriding the base. Concretely, the 
following two definitions might be unwanted:
* Template variables defined in the base causing the `$base` directive to override them
(e.g. `idTemplate: http://{env}.a.ml/{resource}`, here the `env` variable will be overwritten by $base). 

    *This will result in a warning in the dialect definition.* 

* Templates that only consist of a base URI causing the `$base` directive to override the full template
(e.g. `idTemplate: htpp://a.ml/`, here the full template will be overwritten by $base)

    *This will NOT result in any warnings/violations in the dialect definition.* 

## ID templates

### Summary
ID template is a mechanism to set the ID of a parsed node (from a dialect instance) using the value of different
properties of the node (in that dialect instance).

### Declaring an ID template
ID templates are specified in the *dialect definition*. These are set using the `idTemplate` facet for the node mapping
responsible for parsing the desired node. The value of an `idTemplate` facet must be a string which can include zero or
more ID template variables written between curly braces (e.g. `{myTemplateVariable}`). ID template variables must match
one of the property mappings in that same node declared in that same node.

Union nodes cannot set ID templates because these don't declare property mappings. ID templates must be set for each
union member.

### Setting the parsed node ID with an ID template
When parsing a dialect instance, the ID template variables get replaced by the actual **URL-encoded** values (a.k.a.
percent-encoded) of the matching property mappings. The resulting string must be a valid URI which will be assigned
as that node's ID.

**Note**: The corresponding properties will contain the original non URL-encoded value.

### Valid examples
#### Example 1: simple case
##### Dialect
```yaml
PersonNode:
  idTemplate: http://people.org/country/{countryName}/people/{personId}
  mapping:
    countryName:
      range: string
      mandatory: true
      unique: true
    personId:
      range: string
      mandatory: true
      unique: true
    firstName:
      range: string
    lastName:
      range: string
```

##### Dialect Instance

```yaml
countryName: Argentina
personId: 1562340
firstName: Lionel
lastName: Messi
```

##### Parsed node

```json
{
  "@id": "http://people.org/country/Argentina/people/1562340",
  "countryName": "Argentina",
  "personId": "1562340",
  "firstName": "Lionel",
  "lastName": "Messi"
}
```
Notice that the ID of the parsed node gets set using the provided template, replacing the template variables
`{countryName}` and `{personId}` with the values of the parsed property mappings `countryName` and `personId`, which in
this case are `Argentina` and `1562340`

#### Example 2: URL-encoded string
##### Dialect
```yaml
PersonNode:
  idTemplate: http://people.org/people/{fullName}
  mapping:
    fullName:
      range: string
      mandatory: true
      unique: true
```

##### Dialect Instance

```yaml
fullName: Lionel Messi
```

##### Parsed node

```json
{
  "@id": "http://people.org/people/Lionel%20Messi",
  "fullName": "Lionel Messi"
}
```
Notice that the space character ' ' in the dialect instance gets encoded as `%20` in the node ID but keeps its original
value in the parsed property.

### Validation of an ID template definition
When not met the following conditions will raise a **violation** in the dialect definition:

* An ID template variable does not match any property mapping
* An ID template variable matches a non-mandatory property mapping
* An ID template variable matches a non-unique property mapping
* An ID template variable matches a property mapping with a non-scalar range
* An ID template variable matches a property mapping that allows multiple values (`allowMultiple: true`)
* Defining an ID template on a union node
* Defining an ID template which will never produce a valid URI

## Document nodes linking
In AML it is possible to link nodes directly in the parsed graph. This is done by enabling linking in the dialect 
definition. Example of linked nodes can be:
* Nodes from the same document
* Nodes from other documents parsed with the same dialect
* Nodes form other documents parsed with a different dialect

AML linking is enabled in the dialect definition using the `isLink: [boolean]` facet for a *property mapping*. 

### Definitions
#### Link target
*Target node*: is the node which will be the target of the link property

*Target document*: is the document which defines the target node

*Target node mapping*: is the node mapping responsible for parsing the target node. It is the range of the link property
mapping. It can be defined either within the same dialect, in a dialect library or in a fragment.

*Target dialect/library*: is the dialect/library which defines the target node mapping. If the target node mapping 
is defined in a fragment, then it is the dialect/library that includes that fragment.

#### Link source
*Source node*: is the node which is parsed with the link property mapping

*Source document*: is the document which defines the source node

*Source node mapping*: is the node which defined the link property mapping

*Source dialect/library*: is the dialect/library which defines the source node mapping. If the source node mapping 
is defined in a fragment, then it is the dialect/library that includes that fragment.

### Example usage

#### Source node mapping:
```yaml
MyNode:
  mapping:
    myLinkProperty:
      range: Person
      isLink: true
```

#### Source document:
```yaml
myLinkProperty: http://test.com/JohnDoe
```

#### Parsed source document:
```json
{
  "@id": "...",
  "@type": ["#/declarations/MyNode", "meta:DialectDomainElement", "document:DomainElement"],
  "data:myLinkProperty": {
    "@id": "http://test.com/JohnDoe",
    "@type": ["#/declarations/Person", "meta:DialectDomainElement", "document:DomainElement"]
  }
}
```

In this example we define that the property `myLinkProperty` which points to a node of type `Person` **is a link**.
This means that, in the document, the value of the `myLinkProperty` will be used to **construct the ID of the target 
node**. This can be seen in the ID of the node value of the `data:myLinkProperty` property in the parsed source document. 

Another important aspect to notice is that links are typed. The node value of the `data:myLinkProperty` property in the 
parsed source document has a `@type` property which includes the original `Person` type we have defined in the source
dialect.

Target node IDs can be constructed in two ways: *URI links* and *ID template links*.

### URI links
URI links are the most straight forward. These are defined as:

> **URI link**: link property value which represents the URI of the target node

In URI links the ID of the target node is provided "as-is" in the document. This ID can be represented in multiple ways:
* A string representation with the URI of the target node
* A map representation containing the `$id` entry

####  Example usage

##### Source node mapping:
```yaml
MyNode:
  mapping:
    myLinkProperty:
      range: Person
      allowMultiple: true
      isLink: true
```

##### Source document:
```yaml
myLinkProperty: 
  - http://test.com/JohnDoe           # URI link string
  - $id: http://test.com/JohnDoe      # URI link map
```

In this example all of the nodes in the array point to the same node using *different representations* of URI links.
URI links can point to any node regardless of where it was defined, as long a URI is provided for it.   

### ID template links
ID template links re-use idTemplate definitions from the *target node mapping* to construct links target URIs. ID 
template links are defined as follows:

> ID template links: link property map value that represents the values for the variables defined in the id template of the 
> target node mapping

In practice these are maps of property-scalar values. The target node ID will be formed in the same way as a non-link 
node ID with idTemplate. For more information see the idTemplate documentation.

####  Example

##### Target node mapping:
```yaml
TargetNodeMapping:
  idTemplate: http://test.com/{a}/{b}
  mapping:
    a:
      range: string
    b: 
      renge: string
```

##### Target document:
```yaml
# Target node -> http://test.com/people/JohnDoe
a: people
b: JohnDoe
```

##### Source node mapping:
```yaml
MyNode:
  mapping:
    myLinkProperty:
      range: TargetNodeMapping
      isLink: true
```

##### Source document:
```yaml
myLinkProperty: # Link to http://test.com/people/JohnDoe
  a: people
  b: JohnDoe
```

As you can see in the above example, both the target node and the link node use the same ID template definition to 
construct the node ID & target ID respectively. 

### Validation
Links are validated as follows:
* Scalars cannot be linked, setting a scalar as the range of a link property mapping will result in a **violation** in the 
**source dialect definition** (because scalars are not nodes with IDs)
* `$id` directive from URI Links cannot be mixed with variable definitions from the idTemplate from ID Template Links. 
Mixing both mechanisms will result in a **violation** in the **source document definition**.

Both URI Links and ID Template Links support the use of the `$base` directive. When using the `$base` directive all the 
validations described in the `$base` definition apply to links as well. For more information see the `$base` 
documentation in the spec.

#### Validation for URI Links
URI links also include the following extra validations:
* Defining `$base` without `$id` will result in a **violation** in the **source document definition**

#### Validation for ID Template links
When using the ID Template links all the validations described in the idTemplate definition apply to ID Template Links 
as well. 

ID Template Links also include the following extra validations:
* Defining properties in the document which do not relate to variables in the idTemplate will result in **violations** 
in the **source document definition**. The only exception are *discriminator properties* when the target node mapping is a 
union node (for more info see the discriminator definition).

## Node mapping extension

In AML it is possible to extend node mappings definitions with the `extends` facet.

The value of the `extends` facet should be the name of another node mapping, which called the _Parent node mapping_. The
node defining the `extends` facet will be called consequently the _Child node mapping_.

<!-- TODO multiple extension: programmatic API allows to define multiple extension, however only the first parent is used for resolution, other parents are ignored -->

Extending a node mapping reuses the definitions from the parent node mapping that **are not defined** in the child node
mapping. These include:

* Property mappings
* ID Templates

Property mappings in the child node mapping that share the same _name_ as some property mapping the parent node mapping
_override_ that parent property mapping. In the same way ID Templates defined in the child node mapping override ID
Templates defined in the parent node mapping.

<!-- TODO is extension allowed for unions? If so how should union members, discriminators & discriminator values be resolved -->

### Extension is neither subtyping nor polymorphism

In AML node mapping extension is purely structural. This means that when parsing a dialect instance node the node
mapping responsible for parsing that node is a combination of the mapping structure defined in the parent and child node
mappings.

Semantics are not affected by extension. Class terms from parent node mapping are not reflected in child node mapping.
The hierarchical relationship between semantic terms should be represented in an AML Vocabulary, not in a dialect.

The best approximation for polymorphism are _union nodes_. These allow to group several node mappings into one single
node mapping. The relationship between a union node and each of its members in neither hierarchical nor semantic, it is
only structural, just like in node mapping extension. See [Unions](#unions) for more details.

### Examples

#### Example 1: basic extension

##### Dialect

```yaml
ParentNodeMapping:
  classTerm: myExternal.ParentClass
  mapping:
    parentName:
      propertyTerm: myExternal.parentProperty
      range: string

ChildNodeMapping:
  classTerm: myExternal.ChildClass
  extends: ParentNodeMapping
  mapping:
    childName:
      propertyTerm: myExternal.childProperty
      range: string
```

##### Dialect instance (ChildNodeMapping)

```yaml
parentName: Anakin Skywalker
childName: Luke Skywalker
```

##### Parsed node

```json
{
  "@id": "...instance.yaml#/encodes",
  "@type": [
    "http://myexternal.org#ChildClass",
    ...
  ],
  "http://myexternal.org#parentProperty": "Anakin Skywalker",
  "http://myexternal.org#childProperty": "Luke Skywalker"
}
```

As seen in the above example, the parsed node contains both properties:

* `http://myexternal.org#parentProperty` derived from the parent property mapping `parentName`
* `http://myexternal.org#childProperty` derived from the child property mapping `childName`

Notice that only the `http://myexternal.org#ChildClass` class term was included in the `@types` facet of the node. This
is due to the structural non-semantic relationship of node mapping extension.

#### Example 2: property mapping override

##### Dialect

```yaml
ParentNodeMapping:
  classTerm: myExternal.ParentClass
  mapping:
    myProperty:
      propertyTerm: myExternal.parentProperty
      range: string
ChildNodeMapping:
  classTerm: myExternal.ChildClass
  extends: ParentNodeMapping
  mapping:
    myProperty:
      propertyTerm: myExternal.childProperty
      range: string
```

##### Dialect instance (ChildNodeMapping)

```yaml
myProperty: I'm overriden by the child property mapping
```

##### Parsed node

```json
{
  "@id": "...instance.yaml#/encodes",
  "@type": [
    "http://myexternal.org#ChildClass",
    ...
  ],
  "http://myexternal.org#childProperty": "I'm overriden by the child property mapping"
}
```

The above example showcases a child property mapping that overrides a parent property mapping.

Both the child and parent node define the `myProperty` property mapping, each mapping to
`http://myexternal.org#childProperty` and `http://myexternal.org#parentProperty` respectfully. As seen in the parsed
node the `http://myexternal.org#childProperty` overrides the `http://myexternal.org#parentProperty` because both
share the same `myProperty` property mapping name.

#### Example 3: ID Template extension

##### Dialect

```yaml
ParentNodeMapping:
  classTerm: myExternal.ParentClass
  idTemplate: http://myNode.org#{nodeId}
  mapping:
    nodeId:
      propertyTerm: myExternal.parentProperty
      range: string
      mandatory: true
ChildNodeMapping:
  classTerm: myExternal.ChildClass
  extends: ParentNodeMapping
  mapping:
    nodeId:
      propertyTerm: myExternal.childProperty
      range: string
      mandatory: true
```

##### Dialect instance (ChildNodeMapping)

```yaml
nodeId: my-example-node
```

##### Parsed node

```json
    {
  "@id": "http://myNode.org#my-example-node",
  "@type": [
    "http://myexternal.org#ChildClass",
    ...
  ],
  "http://myexternal.org#childProperty": "my-example-node"
}
```
In the above example the parent node defines an ID Template which is reused by the child node. This can be seen in the
parsed node as its ID `http://myNode.org#my-example-node` matches the template definition from the parent while the
`nodeId` property mapping matches the child property `http://myexternal.org#childProperty`.

Notice that ID Template variables must match property mappings in the parent node mapping definition which can be
then optionally overriden by child property mappings. See [ID Templates](#id-templates).

### Validation
Node mapping extension definition validations:
1. Defining node mapping extensions in which either the parent or child node mapping is a _union node_ will raise a
   **violation** in the _dialect definition_. Union nodes cannot define property mappings nor ID Templates so it does not
   make sense to define extensions between these and will be considered an error.
2. ID Template definitions from parent node mappings are validated in child mappings as if were defined by the child
   node mapping. All the mentioned validations in [ID Templates](#id-templates) apply for child node mappings as well.
3. Property mappings from parent node mappings cannot share _property terms_ with any of the property mappings from the
   child node. Doing so will result in a **violation** in the _dialect definition_.

Node mapping extension dialect instance validations:
1. Non-overriden property mappings from parent node mappings will produce the same validations in child node mappings as if were
   defined by the child node mapping in _dialect instance validation_. Example: defining a mandatory property mapping in the
   parent node means that nodes parsed with either the parent or child node mappings must satisfy this mandatory property
   mapping (unless overriden by the child node).


## Reference styles

AML processors must support three different styles of references across the modular document instances for a dialect:

### Include references

Include references marked by the referencing directive introduced by the strings `!include` or `$include` can be used to reference to the encoded node of a fragment

### Library aliases

Nodes collected in a reusable library document can be referenced in a target document using a library alias using the `use` keyword to introduce the library alias and then a `{alias}.{declaration}` notation for the actual node reference

### Hash references

Hash references, introduced by the `$ref` referencing directive whose value must be the ID/URI of the referenced element, for example within a library.

### Dialect references

Dialect references, introduced by the `$dialect` referencing directive can be used to provide information about the dialect for a full document, for example, when using JSON syntax for a dialect instance document or for the node mapping in a dynamic node.

## References

- [Berners-Lee, T., Masinter, L., and M. McCahill, "Uniform Resource Locators (URL)", RFC 1738, December 1994.](https://datatracker.ietf.org/doc/html/rfc1738)
- [RDF 1.1 Concepts and Abstract Syntax](https://www.w3.org/TR/rdf11-concepts/)
- [SHACL](https://www.w3.org/TR/shacl/)
- [OWL 2 Web Ontology Language Document Overview (2nd Edition)](https://www.w3.org/TR/owl2-overview/)
- [W3C XML Schema Definition Language (XSD) 1.1](http://www.w3.org/XML/Schema)
- [YAML Aint Markup Language](http://www.yaml.org/spec/1.2/spec.html)
- [RFC 4627 - The application/json Media Type for Javascript Object Notation (JSON)](https://tools.ietf.org/html/rfc4627)
