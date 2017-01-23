## DISCLAIMER

This document describes a feature that is currently still in early development/planning.

## Views

A type can define custom views for transforming result sets before it is passed
to the client.

```yaml
types: 
  project: 
    views: 
      export: !my_custom_view 
```

A view is an object with functions `init`, `map`, `reduce`, `empty`, `encode`.
A default implementations might look something like this:

```coffee
view = ()->
  init: (type)->
  map: (hit)->hit
  reduce: (a,b)->[a...,b]
  empty: ->[]
  encode: (result)->JSON.stringify result
```

Those functions are working together to create a responseBody from result set.
They are called like this:

```coffee
result = hits
  .map view.map
  .reduce view.reduce, view.empty()
responseBody = view.encode result
```

You can define as many views as you like. IRMa looks at the value of the `view`
query parameter to determine which view to use. If no such parameter exists in
the request, IRMa will choose the view with the key `default`.  This view is
implicitly defined for all types but you can override it with your own
implementation.

While there is nothing stopping you from creating your own views, there are two
powerful predefined views that you should know about: The _Default View_ and
the _Table View_.

## The Default View (`!default-view`)

Unless you override it in your configuration, every type has at least one
implicit View with the key `default`. This view is an instance of
`DefaultView`. There are no options for this type of view as it guesses
everything from looking at the types attributes.

(NOT IMPLEMENTED YET)

## The Table View (`!table-view`)

The Table View is a View that represents a result set in a tabular fashion.  By
default, it will include all attributes defined by the type and figure out some
default way to represent their label and values. The columns will appear in the
same order as the corresponding attributes appear in the configuration.

There are several ways to customize this behaviour.

You can specify which columns should be displayed and in which order:

```yaml
types:
  project:
    views:
      export: !table-view
        columns:
          - fach
          - name
          - rolle
```

The view will only contain the listed columns in the exact given order. Each
entry is either an instance of `ColumnRenderer` or it is passed to the
constructor of `AttributeColumnRenderer` to create such an instance.  The
constructor can handle simple attribute names instead of an options object,
thus allowing the short-hand syntax used above. But of course you can create
your own custom renderer and even create columns that do not correspond to any
of the attributes.

```yaml
types:
  project:
    views:
      export: !table-view
        columns:
          - key: versanddatum
            label: "Year"
            value: !coffee |
              (src)->(new Date(src)).getFullYear()
          - !my-custom-renderer
            key: status
            label: Status
            value: !coffee |
              (hit,type) -> if hit.data.foo then 2+foo else 42
```

If you want to keep the default sequence of attribute columns and only
customize the rendering of particular renderers, let `columns` be an object
rather than an array. Add a property for each column you want to customize,
using the attribute name as key. As above, if the value is an instance of
`ColumnRenderer` it will be used verbatime, otherwise it will be used to
construct a `AttributeColumnRenderer`.  In the latter case, if you do not
provide a property `key`, the attribute name will be used.

```yaml
types:
  project:
    views:
      export: !table-view
        columns:
          versanddatum:
            label: "Year"
            value: !coffee |
              (src)->(new Date(src)).getFullYear()
```
