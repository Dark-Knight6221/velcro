import ../src/velcro

type
  SomeObj = ref object
    velcro: VelcroObj
    field1: int
    field2: string
  SomeComp = ref object of VelcroComp
    field1: bool
    field2: float

var foo = SomeObj(
  velcro: initVelcro(),
  field1: 2,
  field2: "Bar"
)
var comp = SomeComp(
  field1: true,
  field2: 3.141
)

foo.add comp
assert foo[SomeComp].field1 == true
assert foo[SomeComp].field2 == 3.141
foo[SomeComp].field1 = false
foo[SomeComp].field2 = 1.41
assert foo[SomeComp].field1 == false
assert foo[SomeComp].field2 == 1.41

assert foo.has SomeComp
foo.delete SomeComp
assert not foo.has SomeComp

echo "PASS"
