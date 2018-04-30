
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
bool  TypedRichNode<Unit>::isLiteral(VM vm) {
  return _self.access<Unit>().isLiteral(vm);
}

inline
bool  TypedRichNode<Unit>::lookupFeature(VM vm, class mozart::RichNode feature, nullable<class mozart::UnstableNode &> value) {
  return _self.access<Unit>().lookupFeature(vm, feature, value);
}

inline
bool  TypedRichNode<Unit>::lookupFeature(VM vm, nativeint feature, nullable<class mozart::UnstableNode &> value) {
  return _self.access<Unit>().lookupFeature(vm, feature, value);
}

inline
bool  TypedRichNode<Unit>::isRecord(VM vm) {
  return _self.access<Unit>().isRecord(vm);
}

inline
bool  TypedRichNode<Unit>::isTuple(VM vm) {
  return _self.access<Unit>().isTuple(vm);
}

inline
class mozart::UnstableNode  TypedRichNode<Unit>::label(VM vm) {
  return _self.access<Unit>().label(_self, vm);
}

inline
size_t  TypedRichNode<Unit>::width(VM vm) {
  return _self.access<Unit>().width(vm);
}

inline
class mozart::UnstableNode  TypedRichNode<Unit>::arityList(VM vm) {
  return _self.access<Unit>().arityList(vm);
}

inline
class mozart::UnstableNode  TypedRichNode<Unit>::clone(VM vm) {
  return _self.access<Unit>().clone(_self, vm);
}

inline
class mozart::UnstableNode  TypedRichNode<Unit>::waitOr(VM vm) {
  return _self.access<Unit>().waitOr(vm);
}

inline
bool  TypedRichNode<Unit>::testRecord(VM vm, class mozart::RichNode arity) {
  return _self.access<Unit>().testRecord(vm, arity);
}

inline
bool  TypedRichNode<Unit>::testTuple(VM vm, class mozart::RichNode label, size_t width) {
  return _self.access<Unit>().testTuple(_self, vm, label, width);
}

inline
bool  TypedRichNode<Unit>::testLabel(VM vm, class mozart::RichNode label) {
  return _self.access<Unit>().testLabel(_self, vm, label);
}

inline
bool  TypedRichNode<Unit>::equals(VM vm, class mozart::RichNode right) {
  return _self.access<Unit>().equals(vm, right);
}

inline
int  TypedRichNode<Unit>::compareFeatures(VM vm, class mozart::RichNode right) {
  return _self.access<Unit>().compareFeatures(vm, right);
}

inline
atom_t  TypedRichNode<Unit>::getPrintName(VM vm) {
  return _self.access<Unit>().getPrintName(vm);
}

inline
bool  TypedRichNode<Unit>::isName(VM vm) {
  return _self.access<Unit>().isName(vm);
}

inline
class mozart::UnstableNode  TypedRichNode<Unit>::serialize(VM vm, SE se) {
  return _self.access<Unit>().serialize(vm, se);
}

inline
void  TypedRichNode<Unit>::printReprToStream(VM vm, std::ostream & out, int depth, int width) {
  _self.access<Unit>().printReprToStream(vm, out, depth, width);
}
