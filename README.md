# Velcro
## Basic introduction
Velcro is a lightweight Nim ECS library for runtime-attached components.
## The two modes
### Default
By default, your parent objects need to have a `velcro` field with the type of `VelcroObj`.
Components need to inherit from `VelcroComp`.
You can attach and detach these with `add` and `delete`.
The parent object and the component can have any other field, as they don't influence the workings of the library.
You can check whether an object has a specific field through `has`, where you pass the object and the component's `typedesc`.
To access a component, you can index it: `yourVelcroObj[YourVelcroComp]`
- **Note**: You index an initialized value with the type's name.
### ECS
To enable this mode, you have two options:
- Through a compiler flag: `-d:velcroOwned`
- Through a pragma: `{.define:velcroOwned.}`

This changes how the library handles data, so now your parent objects have to inherit from `VelcroObj`.
Components work the same. You can still attach and detach with `add` and `delete`.
To have your objects in the database, you have to upload them through `upload`.
To query the DB, you can use
- `querySet`, which works with any number of values but returns a `HashSet`
  - If there are multiple values, the sets are intersected
- `query`, which converts the `HashSet` to a `seq`, but only works with a single input
- or `querySetAny`, which is similar to `querySet`, but unionizes the values instead.
Queries return a `VelcroHandler`, which can be used the same as the actual object.
- **Note**: You can't access the actual object's fields after you have uploaded it, only the original variable can.