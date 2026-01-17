
void TypeInfoOf<UniqueName>::printReprToStream(VM vm, RichNode self, std::ostream& out,
                    int depth, int width) const {
  assert(self.is<UniqueName>());
  self.as<UniqueName>().printReprToStream(vm, out, depth, width);
}

UnstableNode TypeInfoOf<UniqueName>::serialize(VM vm, SE s, RichNode from) const {
  assert(from.is<UniqueName>());
  return from.as<UniqueName>().serialize(vm, s);
}

void TypeInfoOf<UniqueName>::gCollect(GC gc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.make<UniqueName>(gc->vm, gc, from.access<UniqueName>());
}

void TypeInfoOf<UniqueName>::gCollect(GC gc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.make<UniqueName>(gc->vm, gc, from.access<UniqueName>());
}

void TypeInfoOf<UniqueName>::sClone(SC sc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.make<UniqueName>(sc->vm, sc, from.access<UniqueName>());
}

void TypeInfoOf<UniqueName>::sClone(SC sc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.make<UniqueName>(sc->vm, sc, from.access<UniqueName>());
}

int TypeInfoOf<UniqueName>::compareFeatures(VM vm, RichNode lhs, RichNode rhs) const {
  return lhs.as<UniqueName>().compareFeatures(vm, rhs);
}


inline
bool  TypedRichNode<UniqueName>::isLiteral(mozart::VM vm) {
  return _self.access<UniqueName>().isLiteral(vm);
}

inline
bool  TypedRichNode<UniqueName>::lookupFeature(mozart::VM vm, mozart::RichNode feature, nullable<mozart::UnstableNode &> value) {
  return _self.access<UniqueName>().lookupFeature(vm, feature, value);
}

inline
bool  TypedRichNode<UniqueName>::lookupFeature(mozart::VM vm, mozart::nativeint feature, nullable<mozart::UnstableNode &> value) {
  return _self.access<UniqueName>().lookupFeature(vm, feature, value);
}

inline
bool  TypedRichNode<UniqueName>::isRecord(mozart::VM vm) {
  return _self.access<UniqueName>().isRecord(vm);
}

inline
bool  TypedRichNode<UniqueName>::isTuple(mozart::VM vm) {
  return _self.access<UniqueName>().isTuple(vm);
}

inline
mozart::UnstableNode  TypedRichNode<UniqueName>::label(mozart::VM vm) {
  return _self.access<UniqueName>().label(_self, vm);
}

inline
size_t  TypedRichNode<UniqueName>::width(mozart::VM vm) {
  return _self.access<UniqueName>().width(vm);
}

inline
mozart::UnstableNode  TypedRichNode<UniqueName>::arityList(mozart::VM vm) {
  return _self.access<UniqueName>().arityList(vm);
}

inline
mozart::UnstableNode  TypedRichNode<UniqueName>::clone(mozart::VM vm) {
  return _self.access<UniqueName>().clone(_self, vm);
}

inline
mozart::UnstableNode  TypedRichNode<UniqueName>::waitOr(mozart::VM vm) {
  return _self.access<UniqueName>().waitOr(vm);
}

inline
bool  TypedRichNode<UniqueName>::testRecord(mozart::VM vm, mozart::RichNode arity) {
  return _self.access<UniqueName>().testRecord(vm, arity);
}

inline
bool  TypedRichNode<UniqueName>::testTuple(mozart::VM vm, mozart::RichNode label, size_t width) {
  return _self.access<UniqueName>().testTuple(_self, vm, label, width);
}

inline
bool  TypedRichNode<UniqueName>::testLabel(mozart::VM vm, mozart::RichNode label) {
  return _self.access<UniqueName>().testLabel(_self, vm, label);
}

inline
mozart::unique_name_t  TypedRichNode<UniqueName>::value() {
  return _self.access<UniqueName>().value();
}

inline
bool  TypedRichNode<UniqueName>::equals(mozart::VM vm, mozart::RichNode right) {
  return _self.access<UniqueName>().equals(vm, right);
}

inline
int  TypedRichNode<UniqueName>::compareFeatures(mozart::VM vm, mozart::RichNode right) {
  return _self.access<UniqueName>().compareFeatures(vm, right);
}

inline
mozart::atom_t  TypedRichNode<UniqueName>::getPrintName(mozart::VM vm) {
  return _self.access<UniqueName>().getPrintName(vm);
}

inline
bool  TypedRichNode<UniqueName>::isName(mozart::VM vm) {
  return _self.access<UniqueName>().isName(vm);
}

inline
mozart::UnstableNode  TypedRichNode<UniqueName>::serialize(mozart::VM vm, mozart::SE se) {
  return _self.access<UniqueName>().serialize(vm, se);
}

inline
void  TypedRichNode<UniqueName>::printReprToStream(mozart::VM vm, std::ostream & out, int depth, int width) {
  _self.access<UniqueName>().printReprToStream(vm, out, depth, width);
}
