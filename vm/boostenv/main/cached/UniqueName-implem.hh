
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
bool  TypedRichNode<UniqueName>::isLiteral(VM vm) {
  return _self.access<UniqueName>().isLiteral(vm);
}

inline
bool  TypedRichNode<UniqueName>::lookupFeature(VM vm, class mozart::RichNode feature, nullable<class mozart::UnstableNode &> value) {
  return _self.access<UniqueName>().lookupFeature(vm, feature, value);
}

inline
bool  TypedRichNode<UniqueName>::lookupFeature(VM vm, nativeint feature, nullable<class mozart::UnstableNode &> value) {
  return _self.access<UniqueName>().lookupFeature(vm, feature, value);
}

inline
bool  TypedRichNode<UniqueName>::isRecord(VM vm) {
  return _self.access<UniqueName>().isRecord(vm);
}

inline
bool  TypedRichNode<UniqueName>::isTuple(VM vm) {
  return _self.access<UniqueName>().isTuple(vm);
}

inline
class mozart::UnstableNode  TypedRichNode<UniqueName>::label(VM vm) {
  return _self.access<UniqueName>().label(_self, vm);
}

inline
size_t  TypedRichNode<UniqueName>::width(VM vm) {
  return _self.access<UniqueName>().width(vm);
}

inline
class mozart::UnstableNode  TypedRichNode<UniqueName>::arityList(VM vm) {
  return _self.access<UniqueName>().arityList(vm);
}

inline
class mozart::UnstableNode  TypedRichNode<UniqueName>::clone(VM vm) {
  return _self.access<UniqueName>().clone(_self, vm);
}

inline
class mozart::UnstableNode  TypedRichNode<UniqueName>::waitOr(VM vm) {
  return _self.access<UniqueName>().waitOr(vm);
}

inline
bool  TypedRichNode<UniqueName>::testRecord(VM vm, class mozart::RichNode arity) {
  return _self.access<UniqueName>().testRecord(vm, arity);
}

inline
bool  TypedRichNode<UniqueName>::testTuple(VM vm, class mozart::RichNode label, size_t width) {
  return _self.access<UniqueName>().testTuple(_self, vm, label, width);
}

inline
bool  TypedRichNode<UniqueName>::testLabel(VM vm, class mozart::RichNode label) {
  return _self.access<UniqueName>().testLabel(_self, vm, label);
}

inline
unique_name_t  TypedRichNode<UniqueName>::value() {
  return _self.access<UniqueName>().value();
}

inline
bool  TypedRichNode<UniqueName>::equals(VM vm, class mozart::RichNode right) {
  return _self.access<UniqueName>().equals(vm, right);
}

inline
int  TypedRichNode<UniqueName>::compareFeatures(VM vm, class mozart::RichNode right) {
  return _self.access<UniqueName>().compareFeatures(vm, right);
}

inline
atom_t  TypedRichNode<UniqueName>::getPrintName(VM vm) {
  return _self.access<UniqueName>().getPrintName(vm);
}

inline
bool  TypedRichNode<UniqueName>::isName(VM vm) {
  return _self.access<UniqueName>().isName(vm);
}

inline
class mozart::UnstableNode  TypedRichNode<UniqueName>::serialize(VM vm, SE se) {
  return _self.access<UniqueName>().serialize(vm, se);
}

inline
void  TypedRichNode<UniqueName>::printReprToStream(VM vm, std::ostream & out, int depth, int width) {
  _self.access<UniqueName>().printReprToStream(vm, out, depth, width);
}
