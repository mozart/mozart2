
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
mozart::nativeint  TypedRichNode<SmallInt>::value() {
  return _self.access<SmallInt>().value();
}

inline
bool  TypedRichNode<SmallInt>::equals(mozart::VM vm, mozart::RichNode right) {
  return _self.access<SmallInt>().equals(vm, right);
}

inline
int  TypedRichNode<SmallInt>::compareFeatures(mozart::VM vm, mozart::RichNode right) {
  return _self.access<SmallInt>().compareFeatures(vm, right);
}

inline
int  TypedRichNode<SmallInt>::compare(mozart::VM vm, mozart::RichNode right) {
  return _self.access<SmallInt>().compare(_self, vm, right);
}

inline
bool  TypedRichNode<SmallInt>::isNumber(mozart::VM vm) {
  return _self.access<SmallInt>().isNumber(vm);
}

inline
bool  TypedRichNode<SmallInt>::isInt(mozart::VM vm) {
  return _self.access<SmallInt>().isInt(vm);
}

inline
bool  TypedRichNode<SmallInt>::isFloat(mozart::VM vm) {
  return _self.access<SmallInt>().isFloat(vm);
}

inline
mozart::UnstableNode  TypedRichNode<SmallInt>::opposite(mozart::VM vm) {
  return _self.access<SmallInt>().opposite(vm);
}

inline
mozart::UnstableNode  TypedRichNode<SmallInt>::add(mozart::VM vm, mozart::RichNode right) {
  return _self.access<SmallInt>().add(vm, right);
}

inline
mozart::UnstableNode  TypedRichNode<SmallInt>::add(mozart::VM vm, mozart::nativeint b) {
  return _self.access<SmallInt>().add(vm, b);
}

inline
mozart::UnstableNode  TypedRichNode<SmallInt>::subtract(mozart::VM vm, mozart::RichNode right) {
  return _self.access<SmallInt>().subtract(vm, right);
}

inline
mozart::UnstableNode  TypedRichNode<SmallInt>::subtractValue(mozart::VM vm, mozart::nativeint b) {
  return _self.access<SmallInt>().subtractValue(vm, b);
}

inline
mozart::UnstableNode  TypedRichNode<SmallInt>::multiply(mozart::VM vm, mozart::RichNode right) {
  return _self.access<SmallInt>().multiply(vm, right);
}

inline
mozart::UnstableNode  TypedRichNode<SmallInt>::multiplyValue(mozart::VM vm, mozart::nativeint b) {
  return _self.access<SmallInt>().multiplyValue(vm, b);
}

inline
mozart::UnstableNode  TypedRichNode<SmallInt>::div(mozart::VM vm, mozart::RichNode right) {
  return _self.access<SmallInt>().div(vm, right);
}

inline
mozart::UnstableNode  TypedRichNode<SmallInt>::divValue(mozart::VM vm, mozart::nativeint b) {
  return _self.access<SmallInt>().divValue(vm, b);
}

inline
mozart::UnstableNode  TypedRichNode<SmallInt>::mod(mozart::VM vm, mozart::RichNode right) {
  return _self.access<SmallInt>().mod(vm, right);
}

inline
mozart::UnstableNode  TypedRichNode<SmallInt>::modValue(mozart::VM vm, mozart::nativeint b) {
  return _self.access<SmallInt>().modValue(vm, b);
}

inline
mozart::UnstableNode  TypedRichNode<SmallInt>::abs(mozart::VM vm) {
  return _self.access<SmallInt>().abs(vm);
}

inline
void  TypedRichNode<SmallInt>::printReprToStream(mozart::VM vm, std::ostream & out, int depth, int width) {
  _self.access<SmallInt>().printReprToStream(vm, out, depth, width);
}
