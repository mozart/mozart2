
void TypeInfoOf<Boolean>::printReprToStream(VM vm, RichNode self, std::ostream& out,
                    int depth, int width) const {
  assert(self.is<Boolean>());
  self.as<Boolean>().printReprToStream(vm, out, depth, width);
}

UnstableNode TypeInfoOf<Boolean>::serialize(VM vm, SE s, RichNode from) const {
  assert(from.is<Boolean>());
  return from.as<Boolean>().serialize(vm, s);
}

void TypeInfoOf<Boolean>::gCollect(GC gc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.make<Boolean>(gc->vm, gc, from.access<Boolean>());
}

void TypeInfoOf<Boolean>::gCollect(GC gc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.make<Boolean>(gc->vm, gc, from.access<Boolean>());
}

void TypeInfoOf<Boolean>::sClone(SC sc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.make<Boolean>(sc->vm, sc, from.access<Boolean>());
}

void TypeInfoOf<Boolean>::sClone(SC sc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.make<Boolean>(sc->vm, sc, from.access<Boolean>());
}

int TypeInfoOf<Boolean>::compareFeatures(VM vm, RichNode lhs, RichNode rhs) const {
  return lhs.as<Boolean>().compareFeatures(vm, rhs);
}


inline
bool  TypedRichNode<Boolean>::isLiteral(mozart::VM vm) {
  return _self.access<Boolean>().isLiteral(vm);
}

inline
bool  TypedRichNode<Boolean>::lookupFeature(mozart::VM vm, mozart::RichNode feature, nullable<mozart::UnstableNode &> value) {
  return _self.access<Boolean>().lookupFeature(vm, feature, value);
}

inline
bool  TypedRichNode<Boolean>::lookupFeature(mozart::VM vm, mozart::nativeint feature, nullable<mozart::UnstableNode &> value) {
  return _self.access<Boolean>().lookupFeature(vm, feature, value);
}

inline
bool  TypedRichNode<Boolean>::isRecord(mozart::VM vm) {
  return _self.access<Boolean>().isRecord(vm);
}

inline
bool  TypedRichNode<Boolean>::isTuple(mozart::VM vm) {
  return _self.access<Boolean>().isTuple(vm);
}

inline
mozart::UnstableNode  TypedRichNode<Boolean>::label(mozart::VM vm) {
  return _self.access<Boolean>().label(_self, vm);
}

inline
size_t  TypedRichNode<Boolean>::width(mozart::VM vm) {
  return _self.access<Boolean>().width(vm);
}

inline
mozart::UnstableNode  TypedRichNode<Boolean>::arityList(mozart::VM vm) {
  return _self.access<Boolean>().arityList(vm);
}

inline
mozart::UnstableNode  TypedRichNode<Boolean>::clone(mozart::VM vm) {
  return _self.access<Boolean>().clone(_self, vm);
}

inline
mozart::UnstableNode  TypedRichNode<Boolean>::waitOr(mozart::VM vm) {
  return _self.access<Boolean>().waitOr(vm);
}

inline
bool  TypedRichNode<Boolean>::testRecord(mozart::VM vm, mozart::RichNode arity) {
  return _self.access<Boolean>().testRecord(vm, arity);
}

inline
bool  TypedRichNode<Boolean>::testTuple(mozart::VM vm, mozart::RichNode label, size_t width) {
  return _self.access<Boolean>().testTuple(_self, vm, label, width);
}

inline
bool  TypedRichNode<Boolean>::testLabel(mozart::VM vm, mozart::RichNode label) {
  return _self.access<Boolean>().testLabel(_self, vm, label);
}

inline
bool  TypedRichNode<Boolean>::value() {
  return _self.access<Boolean>().value();
}

inline
bool  TypedRichNode<Boolean>::equals(mozart::VM vm, mozart::RichNode right) {
  return _self.access<Boolean>().equals(vm, right);
}

inline
int  TypedRichNode<Boolean>::compareFeatures(mozart::VM vm, mozart::RichNode right) {
  return _self.access<Boolean>().compareFeatures(vm, right);
}

inline
mozart::atom_t  TypedRichNode<Boolean>::getPrintName(mozart::VM vm) {
  return _self.access<Boolean>().getPrintName(vm);
}

inline
bool  TypedRichNode<Boolean>::isName(mozart::VM vm) {
  return _self.access<Boolean>().isName(vm);
}

inline
mozart::UnstableNode  TypedRichNode<Boolean>::serialize(mozart::VM vm, mozart::SE se) {
  return _self.access<Boolean>().serialize(vm, se);
}

inline
void  TypedRichNode<Boolean>::printReprToStream(mozart::VM vm, std::ostream & out, int depth, int width) {
  _self.access<Boolean>().printReprToStream(vm, out, depth, width);
}
