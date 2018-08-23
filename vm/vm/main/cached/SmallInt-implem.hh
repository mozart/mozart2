
void TypeInfoOf<SmallInt>::printReprToStream(VM vm, RichNode self, std::ostream& out,
                    int depth, int width) const {
  assert(self.is<SmallInt>());
  self.as<SmallInt>().printReprToStream(vm, out, depth, width);
}

void TypeInfoOf<SmallInt>::gCollect(GC gc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.make<SmallInt>(gc->vm, gc, from.access<SmallInt>());
}

void TypeInfoOf<SmallInt>::gCollect(GC gc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.make<SmallInt>(gc->vm, gc, from.access<SmallInt>());
}

void TypeInfoOf<SmallInt>::sClone(SC sc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.make<SmallInt>(sc->vm, sc, from.access<SmallInt>());
}

void TypeInfoOf<SmallInt>::sClone(SC sc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.make<SmallInt>(sc->vm, sc, from.access<SmallInt>());
}

int TypeInfoOf<SmallInt>::compareFeatures(VM vm, RichNode lhs, RichNode rhs) const {
  return lhs.as<SmallInt>().compareFeatures(vm, rhs);
}


inline
nativeint  TypedRichNode<SmallInt>::value() {
  return _self.access<SmallInt>().value();
}

inline
bool  TypedRichNode<SmallInt>::equals(VM vm, class mozart::RichNode right) {
  return _self.access<SmallInt>().equals(vm, right);
}

inline
int  TypedRichNode<SmallInt>::compareFeatures(VM vm, class mozart::RichNode right) {
  return _self.access<SmallInt>().compareFeatures(vm, right);
}

inline
int  TypedRichNode<SmallInt>::compare(VM vm, class mozart::RichNode right) {
  return _self.access<SmallInt>().compare(_self, vm, right);
}

inline
bool  TypedRichNode<SmallInt>::isNumber(VM vm) {
  return _self.access<SmallInt>().isNumber(vm);
}

inline
bool  TypedRichNode<SmallInt>::isInt(VM vm) {
  return _self.access<SmallInt>().isInt(vm);
}

inline
bool  TypedRichNode<SmallInt>::isFloat(VM vm) {
  return _self.access<SmallInt>().isFloat(vm);
}

inline
class mozart::UnstableNode  TypedRichNode<SmallInt>::opposite(VM vm) {
  return _self.access<SmallInt>().opposite(vm);
}

inline
class mozart::UnstableNode  TypedRichNode<SmallInt>::add(VM vm, class mozart::RichNode right) {
  return _self.access<SmallInt>().add(vm, right);
}

inline
class mozart::UnstableNode  TypedRichNode<SmallInt>::add(VM vm, nativeint b) {
  return _self.access<SmallInt>().add(vm, b);
}

inline
class mozart::UnstableNode  TypedRichNode<SmallInt>::subtract(VM vm, class mozart::RichNode right) {
  return _self.access<SmallInt>().subtract(vm, right);
}

inline
class mozart::UnstableNode  TypedRichNode<SmallInt>::subtractValue(VM vm, nativeint b) {
  return _self.access<SmallInt>().subtractValue(vm, b);
}

inline
class mozart::UnstableNode  TypedRichNode<SmallInt>::multiply(VM vm, class mozart::RichNode right) {
  return _self.access<SmallInt>().multiply(vm, right);
}

inline
class mozart::UnstableNode  TypedRichNode<SmallInt>::multiplyValue(VM vm, nativeint b) {
  return _self.access<SmallInt>().multiplyValue(vm, b);
}

inline
class mozart::UnstableNode  TypedRichNode<SmallInt>::div(VM vm, class mozart::RichNode right) {
  return _self.access<SmallInt>().div(vm, right);
}

inline
class mozart::UnstableNode  TypedRichNode<SmallInt>::divValue(VM vm, nativeint b) {
  return _self.access<SmallInt>().divValue(vm, b);
}

inline
class mozart::UnstableNode  TypedRichNode<SmallInt>::mod(VM vm, class mozart::RichNode right) {
  return _self.access<SmallInt>().mod(vm, right);
}

inline
class mozart::UnstableNode  TypedRichNode<SmallInt>::modValue(VM vm, nativeint b) {
  return _self.access<SmallInt>().modValue(vm, b);
}

inline
class mozart::UnstableNode  TypedRichNode<SmallInt>::abs(VM vm) {
  return _self.access<SmallInt>().abs(vm);
}

inline
void  TypedRichNode<SmallInt>::printReprToStream(VM vm, std::ostream & out, int depth, int width) {
  _self.access<SmallInt>().printReprToStream(vm, out, depth, width);
}
