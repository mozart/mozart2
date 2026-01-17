
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
bool  TypedRichNode<Atom>::isLiteral(mozart::VM vm) {
  return _self.access<Atom>().isLiteral(vm);
}

inline
bool  TypedRichNode<Atom>::lookupFeature(mozart::VM vm, mozart::RichNode feature, nullable<mozart::UnstableNode &> value) {
  return _self.access<Atom>().lookupFeature(vm, feature, value);
}

inline
bool  TypedRichNode<Atom>::lookupFeature(mozart::VM vm, mozart::nativeint feature, nullable<mozart::UnstableNode &> value) {
  return _self.access<Atom>().lookupFeature(vm, feature, value);
}

inline
bool  TypedRichNode<Atom>::isRecord(mozart::VM vm) {
  return _self.access<Atom>().isRecord(vm);
}

inline
bool  TypedRichNode<Atom>::isTuple(mozart::VM vm) {
  return _self.access<Atom>().isTuple(vm);
}

inline
mozart::UnstableNode  TypedRichNode<Atom>::label(mozart::VM vm) {
  return _self.access<Atom>().label(_self, vm);
}

inline
size_t  TypedRichNode<Atom>::width(mozart::VM vm) {
  return _self.access<Atom>().width(vm);
}

inline
mozart::UnstableNode  TypedRichNode<Atom>::arityList(mozart::VM vm) {
  return _self.access<Atom>().arityList(vm);
}

inline
mozart::UnstableNode  TypedRichNode<Atom>::clone(mozart::VM vm) {
  return _self.access<Atom>().clone(_self, vm);
}

inline
mozart::UnstableNode  TypedRichNode<Atom>::waitOr(mozart::VM vm) {
  return _self.access<Atom>().waitOr(vm);
}

inline
bool  TypedRichNode<Atom>::testRecord(mozart::VM vm, mozart::RichNode arity) {
  return _self.access<Atom>().testRecord(vm, arity);
}

inline
bool  TypedRichNode<Atom>::testTuple(mozart::VM vm, mozart::RichNode label, size_t width) {
  return _self.access<Atom>().testTuple(_self, vm, label, width);
}

inline
bool  TypedRichNode<Atom>::testLabel(mozart::VM vm, mozart::RichNode label) {
  return _self.access<Atom>().testLabel(_self, vm, label);
}

inline
mozart::atom_t  TypedRichNode<Atom>::value() {
  return _self.access<Atom>().value();
}

inline
bool  TypedRichNode<Atom>::equals(mozart::VM vm, mozart::RichNode right) {
  return _self.access<Atom>().equals(vm, right);
}

inline
int  TypedRichNode<Atom>::compareFeatures(mozart::VM vm, mozart::RichNode right) {
  return _self.access<Atom>().compareFeatures(vm, right);
}

inline
mozart::atom_t  TypedRichNode<Atom>::getPrintName(mozart::VM vm) {
  return _self.access<Atom>().getPrintName(vm);
}

inline
bool  TypedRichNode<Atom>::isAtom(mozart::VM vm) {
  return _self.access<Atom>().isAtom(vm);
}

inline
int  TypedRichNode<Atom>::compare(mozart::VM vm, mozart::RichNode right) {
  return _self.access<Atom>().compare(vm, right);
}

inline
void  TypedRichNode<Atom>::printReprToStream(mozart::VM vm, std::ostream & out, int depth, int width) {
  _self.access<Atom>().printReprToStream(vm, out, depth, width);
}
