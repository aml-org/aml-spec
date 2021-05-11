#Semantic Extensions
## Annotation mappings
Annotation mappings are very similar to property mappings. The differences between these two are:
* Annotation mappings are written in instances as annotations intead of regular properties in a node
* Annotation mappings are not bound to a node mapping. For annotation mappings the node to which these apply *might* be defined elsewhere. We write *might* because it can also be defined within the same dialect (can apply to a node mapping) or might it not be defined at all and be open. The "rdf:type" or class to which an annotation mapping applies is identified with the `target` facet
