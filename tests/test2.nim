{.define:velcroOwned.}
import ../src/velcro

type
  SomeObj = ref object of VelcroObj
    field1: int
    field2: string
  SomeComp = ref object of VelcroComp
    field1: bool
    field2: float

var foo = SomeObj(
  field1: 42,
  field2: "Baz"
)
var handler = upload(foo)
var comp = SomeComp(
  field1: false,
  field2: 6.9
)
handler.add comp
assert handler.has SomeComp
assert handler[SomeComp].field1 == false
assert handler[SomeComp].field2 == 6.9
handler[SomeComp].field1 = true
handler[SomeComp].field2 = 4.2
var set = querySet(SomeComp)
assert set == toHashSet([handler])
handler.delete SomeComp
assert not handler.has SomeComp

echo "PASS"
