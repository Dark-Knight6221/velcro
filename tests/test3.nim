{.define:velcroOwned.}
import ../src/velcro

type
  SomeObj = ref object of VelcroObj
    field1: int
    field2: string
  SomeComp1 = ref object of VelcroComp
    field1: bool
    field2: float
  SomeComp2 = ref object of VelcroComp
    field1: string
    field2: bool

var foo = SomeObj(
  field1: 42,
  field2: "Bar"
)
var handler = upload(foo)
var comp1 = SomeComp1(
  field1: true,
  field2: 6.9
)
var comp2 = SomeComp2(
  field1: "Baz",
  field2: false
)

handler.add comp1
handler.add comp2
assert handler.has SomeComp1
assert handler.has SomeComp2
assert handler[SomeComp1].field1 == true
assert handler[SomeComp2].field2 == false
assert query(SomeComp1) == @[handler]
var set1 = querySet(SomeComp1, SomeComp2)
assert set1 == toHashSet([handler])
handler.delete SomeComp1
var set2 = querySet(SomeComp1, SomeComp2)
assert not (set2 == toHashSet([handler]))

echo "PASS"
