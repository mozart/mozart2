
void TypeInfoOf<Unit>::printReprToStream(VM vm, RichNode self, std::ostream& out,
                    int depth, int width) const {
  assert(self.is<Unit>());
  self.as<Unit>().printReprToStream(vm, out, depth, width);
}

UnstableNode TypeInfoOf<Unit>::serialize(VM vm, SE s, RichNode from) const {
  assert(from.is<Unit>());
  return from.as<Unit>().serialize(vm, s);
}

void TypeInfoOf<Unit>::gCollect(GC gc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.make<Unit>(gc->vm, gc, from.access<Unit>());
}

void TypeInfoOf<Unit>::gCollect(GC gc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.make<Unit>(gc->vm, gc, from.access<Unit>());
}

void TypeInfoOf<Unit>::sClone(SC sc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.make<Unit>(sc->vm, sc, from.access<Unit>());
}

void TypeInfoOf<Unit>::sClone(SC sc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.make<Unit>(sc->vm, sc, from.access<Unit>());
}

int TypeInfoOf<Unit>::compareFeatures(VM vm, RichNode lhs, RichNode rhs) const {
  return lhs.as<Unit>().compareFeatures(vm, rhs);
}


inline
bool  TypedRichNode<Unit>::isLiteral(mozart::VM vm) {
  return _self.access<Unit>().isLiteral(vm);
}

inline
bool  TypedRichNode<Unit>::lookupFeature(mozart::VM vm, mozart::RichNode feature, nullable<mozart::UnstableNode &> value) {
  return _self.access<Unit>().lookupFeature(vm, feature, value);
}

inline
bool  TypedRichNode<Unit>::lookupFeature(mozart::VM vm, mozart::nativeint feature, nullable<mozart::UnstableNode &> value) {
  return _self.access<Unit>().lookupFeature(vm, feature, value);
}

inline
bool  TypedRichNode<Unit>::isRecord(mozart::VM vm) {
  return _self.access<Unit>().isRecord(vm);
}

inline
bool  TypedRichNode<Unit>::isTuple(mozart::VM vm) {
  return _self.access<Unit>().isTuple(vm);
}

inline
mozart::UnstableNode  TypedRichNode<Unit>::label(mozart::VM vm) {
  return _self.access<Unit>().label(_self, vm);
}

inline
size_t  TypedRichNode<Unit>::width(mozart::VM vm) {
  return _self.access<Unit>().width(vm);
}

inline
mozart::UnstableNode  TypedRichNode<Unit>::arityList(mozart::VM vm) {
  return _self.access<Unit>().arityList(vm);
}

inline
mozart::UnstableNode  TypedRichNode<Unit>::clone(mozart::VM vm) {
  return _self.access<Unit>().clone(_self, vm);
}

inline
mozart::UnstableNode  TypedRichNode<Unit>::waitOr(mozart::VM vm) {
  return _self.access<Unit>().waitOr(vm);
}

inline
bool  TypedRichNode<Unit>::testRecord(mozart::VM vm, mozart::RichNode arity) {
  return _self.access<Unit>().testRecord(vm, arity);
}

inline
bool  TypedRichNode<Unit>::testTuple(mozart::VM vm, mozart::RichNode label, size_t width) {
  return _self.access<Unit>().testTuple(_self, vm, label, width);
}

inline
bool  TypedRichNode<Unit>::testLabel(mozart::VM vm, mozart::RichNode label) {
  return _self.access<Unit>().testLabel(_self, vm, label);
}

inline
bool  TypedRichNode<Unit>::equals(mozart::VM vm, mozart::RichNode right) {
  return _self.access<Unit>().equals(vm, right);
}

inline
int  TypedRichNode<Unit>::compareFeatures(mozart::VM vm, mozart::RichNode right) {
  return _self.access<Unit>().compareFeatures(vm, right);
}

inline
mozart::atom_t  TypedRichNode<Unit>::getPrintName(mozart::VM vm) {
  return _self.access<Unit>().getPrintName(vm);
}

inline
bool  TypedRichNode<Unit>::isName(mozart::VM vm) {
  return _self.access<Unit>().isName(vm);
}

inline
mozart::UnstableNode  TypedRichNode<Unit>::serialize(mozart::VM vm, mozart::SE se) {
  return _self.access<Unit>().serialize(vm, se);
}

inline
void  TypedRichNode<Unit>::printReprToStream(mozart::VM vm, std::ostream & out, int depth, int width) {
  _self.access<Unit>().printReprToStream(vm, out, depth, width);
}
