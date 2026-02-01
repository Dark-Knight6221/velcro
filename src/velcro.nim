import tables, strutils, macros, macrocache, sets, hashes
export tables, sets

type VelcroComp* = ref object of RootObj
when defined(velcroOwned):
  # Inheritance based
  type
    VelcroObj* = ref object of RootObj
      comps: Table[int, VelcroComp]
    VelcroHandler* = object
      index: int
    VelcroDB = object
      base: seq[VelcroObj]
      tags: Table[int, HashSet[VelcroHandler]]
      index: Table[VelcroObj, VelcroHandler]
else:
  # Field based
  type
    VelcroObj* = object
      comps: Table[int, VelcroComp]
    HasVelcro = concept s
      s.velcro is VelcroObj

const nextTypeId = CacheCounter("nextTypeId")
when defined(velcroOwned):
  # Utils, mostly used for debugging DB
  var velDB = VelcroDB(tags: initTable[int, HashSet[VelcroHandler]]())
  func `$`[T](obj: T): string =
    when T is VelcroObj:
      "(Unknown Object){\n  type: " & $obj.type &
        "\n  comps: " & $obj.comps &
      "\n}"
  func dbToString(db: VelcroDB): string = "DB{\n  base: " & ($db.base).replace("\n", "\n  ") & "\n  tags: " & $db.tags & "\n}"
  proc hash*(x: VelcroObj): int =
    hash(cast[pointer](x))
  when defined(debug):
    proc echoVelDB*(): string = velDB.dbToString()

func typeId*(T: typedesc): int =
  const id = nextTypeId.value
  static:
    inc nextTypeId
  return id
proc initVelcro*(): VelcroObj = VelcroObj(comps: initTable[int, VelcroComp]())
proc compsOf[T](obj: T): var Table[int, VelcroComp] =
  when defined(velcroOwned):
    when T is VelcroHandler:
      return velDB.base[cast[VelcroHandler](obj).index].comps
    elif T is VelcroObj:
      return obj.comps
    raise newException(ValueError, "'" & $T & "' Obj must be VelcroObj or VelcroHandler")
  else:
    return obj.velcro.comps
proc validComp[T](comp: T) =
  static:
    if not (comp of VelcroComp):
      raise newException(ValueError, "Component must inherit VelcroComp")
when defined(velcroOwned):
  proc validObj[T](obj: T) =
    when T is VelcroHandler:
      discard
    elif T is VelcroObj:
      discard
    else:
      {.fatal: "Object is not a valid Velcro".}
else:
  proc validObj[T: HasVelcro](obj: T) = discard
proc validVelcro[T, C](obj: T, comp: C) =
  validComp(comp); validObj(obj)

proc baseAdd[T, C](obj: var T, comp: C) {.inline.} =
  echo compsOf(obj)
  compsOf(obj)[typeId(C)] = cast[VelcroComp](comp)
  echo compsOf(obj)
proc add*[T, C](obj: var T, comp: C) =
  validVelcro(obj, comp)
  baseAdd(obj, comp)
  when defined(velcroOwned):
    when T is VelcroObj:
      if velDB.index.hasKey(obj):
        velDB.tags[typeId(C)].incl velDB.index[obj]
    elif T is VelcroHandler:
      velDB.tags[typeId(C)].incl obj
proc has*[T, C](obj: T, comp: typedesc[C]): bool =
  validObj(obj)
  compsOf(obj).hasKey(typeId(C))
proc delete*[T, C](obj: var T, comp: typedesc[C]) =
  validObj(obj)
  if not obj.has(C):
    raise newException(IndexDefect, "Velcro does not have '" & $C & "' component")
  compsOf(obj).delete(typeId(C))
  when defined(velcroOwned):
    when T is VelcroObj:
      if velDB.index.hasKey(obj):
        velDB.tags[typeId(C)].excl velDB.index[obj]
    elif T is VelcroHandler:
      velDB.tags[typeId(C)].excl obj
proc `[]`*[T, C](obj: T, comp: typedesc[C]): C =
  validObj(obj)
  if not obj.has(C):
    raise newException(IndexDefect, "Velcro does not have '" & $C & "' component")
  cast[C](compsOf(obj)[typeId(C)])

when defined(velcroOwned):
  proc toSeq*(set: HashSet[VelcroHandler]): seq[VelcroHandler] =
    for item in set: result.add item
  proc rawUpload[T](obj: T): VelcroHandler {.inline.} =
    velDB.base.add cast[VelcroObj](obj)
    let handler = VelcroHandler(index: velDB.base.len - 1)
    velDB.index[cast[VelcroObj](obj)] = handler
    handler
  proc upload*[T](obj: T): VelcroHandler =
    validObj(obj)
    let index = rawUpload(obj)
    for key in compsOf(obj).keys:
      if not velDB.tags.hasKey(key):
        velDB.tags[key] = initHashSet[VelcroHandler](64)
      velDB.tags[key].incl index
  proc querySet*[T](query: typedesc[T]): HashSet[VelcroHandler] =
    let key = typeId(query)
    if not velDB.tags.hasKey(key):
      echo dbToString(velDB)
      return initHashSet[VelcroHandler](0)
      #raise newException(IndexDefect, "'" & $query & "' component does not exist in database")
    velDB.tags[key]
  proc query*[T](query: typedesc[T]): seq[VelcroHandler] =
    let key = typeId(query)
    if not velDB.tags.hasKey(key):
      return initHashSet[VelcroHandler](0)
      #raise newException(IndexDefect, "'" & $query & "' component does not exist in database")
    toSeq(velDB.tags[key])
  macro querySet*(args: varargs[untyped]): untyped =
    if args.len == 0:
      error("querySet requires at least one type argument")
    if args.len == 1:
      result = newCall(bindSym"querySet", args[0])
    else:
      result = newStmtList()
      result.add newVarStmt(
        ident"result",
        newCall(bindSym"querySet", args[0])
      )
      for i in 1 ..< args.len:
        result.add newAssignment(
          ident"result",
          infix(ident"result", "*", newCall(bindSym"querySet", args[i]))
        )
      result.add ident"result"
  proc querySetAny*(args: varargs[untyped]): untyped =
    if args.len == 0:
      error("querySet requires at least one type argument")
    if args.len == 1:
      result = newCall(bindSym"querySet", args[0])
    else:
      result = newStmtList()
      result.add newVarStmt(
        ident"result",
        newCall(bindSym"querySet", args[0])
      )
      for i in 1 ..< args.len:
        result.add newAssignment(
          ident"result",
          infix(ident"result", "+", newCall(bindSym"querySet", args[i]))
        )
      result.add ident"result"
