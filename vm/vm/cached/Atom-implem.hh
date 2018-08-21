
void TypeInfoOf<Atom>::printReprToStream(VM vm, RichNode self, std::ostream& out,
                    int depth, int width) const {
  assert(self.is<Atom>());
  self.as<Atom>().printReprToStream(vm, out, depth, width);
}

void TypeInfoOf<Atom>::gCollect(GC gc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.make<Atom>(gc->vm, gc, from.access<Atom>());
}

void TypeInfoOf<Atom>::gCollect(GC gc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.make<Atom>(gc->vm, gc, from.access<Atom>());
}

void TypeInfoOf<Atom>::sClone(SC sc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.make<Atom>(sc->vm, sc, from.access<Atom>());
}

void TypeInfoOf<Atom>::sClone(SC sc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.make<Atom>(sc->vm, sc, from.access<Atom>());
}

int TypeInfoOf<Atom>::compareFeatures(VM vm, RichNode lhs, RichNode rhs) const {
  return lhs.as<Atom>().compareFeatures(vm, rhs);
}


inline
bool  TypedRichNode<Atom>::isLiteral(VM vm) {
  return _self.access<Atom>().isLiteral(vm);
}

inline
bool  TypedRichNode<Atom>::lookupFeature(VM vm, class mozart::RichNode feature, nullable<class mozart::UnstableNode &> value) {
  return _self.access<Atom>().lookupFeature(vm, feature, value);
}

inline
bool  TypedRichNode<Atom>::lookupFeature(VM vm, nativeint feature, nullable<class mozart::UnstableNode &> value) {
  return _self.access<Atom>().lookupFeature(vm, feature, value);
}

inline
bool  TypedRichNode<Atom>::isRecord(VM vm) {
  return _self.access<Atom>().isRecord(vm);
}

inline
bool  TypedRichNode<Atom>::isTuple(VM vm) {
  return _self.access<Atom>().isTuple(vm);
}

inline
class mozart::UnstableNode  TypedRichNode<Atom>::label(VM vm) {
  return _self.access<Atom>().label(_self, vm);
}

inline
size_t  TypedRichNode<Atom>::width(VM vm) {
  return _self.access<Atom>().width(vm);
}

inline
class mozart::UnstableNode  TypedRichNode<Atom>::arityList(VM vm) {
  return _self.access<Atom>().arityList(vm);
}

inline
class mozart::UnstableNode  TypedRichNode<Atom>::clone(VM vm) {
  return _self.access<Atom>().clone(_self, vm);
}

inline
class mozart::UnstableNode  TypedRichNode<Atom>::waitOr(VM vm) {
  return _self.access<Atom>().waitOr(vm);
}

inline
bool  TypedRichNode<Atom>::testRecord(VM vm, class mozart::RichNode arity) {
  return _self.access<Atom>().testRecord(vm, arity);
}

inline
bool  TypedRichNode<Atom>::testTuple(VM vm, class mozart::RichNode label, size_t width) {
  return _self.access<Atom>().testTuple(_self, vm, label, width);
}

inline
bool  TypedRichNode<Atom>::testLabel(VM vm, class mozart::RichNode label) {
  return _self.access<Atom>().testLabel(_self, vm, label);
}

inline
atom_t  TypedRichNode<Atom>::value() {
  return _self.access<Atom>().value();
}

inline
bool  TypedRichNode<Atom>::equals(VM vm, class mozart::RichNode right) {
  return _self.access<Atom>().equals(vm, right);
}

inline
int  TypedRichNode<Atom>::compareFeatures(VM vm, class mozart::RichNode right) {
  return _self.access<Atom>().compareFeatures(vm, right);
}

inline
atom_t  TypedRichNode<Atom>::getPrintName(VM vm) {
  return _self.access<Atom>().getPrintName(vm);
}

inline
bool  TypedRichNode<Atom>::isAtom(VM vm) {
  return _self.access<Atom>().isAtom(vm);
}

inline
int  TypedRichNode<Atom>::compare(VM vm, class mozart::RichNode right) {
  return _self.access<Atom>().compare(vm, right);
}

inline
void  TypedRichNode<Atom>::printReprToStream(VM vm, std::ostream & out, int depth, int width) {
  _self.access<Atom>().printReprToStream(vm, out, depth, width);
}
