
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
bool  TypedRichNode<Boolean>::isLiteral(VM vm) {
  return _self.access<Boolean>().isLiteral(vm);
}

inline
bool  TypedRichNode<Boolean>::lookupFeature(VM vm, class mozart::RichNode feature, nullable<class mozart::UnstableNode &> value) {
  return _self.access<Boolean>().lookupFeature(vm, feature, value);
}

inline
bool  TypedRichNode<Boolean>::lookupFeature(VM vm, nativeint feature, nullable<class mozart::UnstableNode &> value) {
  return _self.access<Boolean>().lookupFeature(vm, feature, value);
}

inline
bool  TypedRichNode<Boolean>::isRecord(VM vm) {
  return _self.access<Boolean>().isRecord(vm);
}

inline
bool  TypedRichNode<Boolean>::isTuple(VM vm) {
  return _self.access<Boolean>().isTuple(vm);
}

inline
class mozart::UnstableNode  TypedRichNode<Boolean>::label(VM vm) {
  return _self.access<Boolean>().label(_self, vm);
}

inline
size_t  TypedRichNode<Boolean>::width(VM vm) {
  return _self.access<Boolean>().width(vm);
}

inline
class mozart::UnstableNode  TypedRichNode<Boolean>::arityList(VM vm) {
  return _self.access<Boolean>().arityList(vm);
}

inline
class mozart::UnstableNode  TypedRichNode<Boolean>::clone(VM vm) {
  return _self.access<Boolean>().clone(_self, vm);
}

inline
class mozart::UnstableNode  TypedRichNode<Boolean>::waitOr(VM vm) {
  return _self.access<Boolean>().waitOr(vm);
}

inline
bool  TypedRichNode<Boolean>::testRecord(VM vm, class mozart::RichNode arity) {
  return _self.access<Boolean>().testRecord(vm, arity);
}

inline
bool  TypedRichNode<Boolean>::testTuple(VM vm, class mozart::RichNode label, size_t width) {
  return _self.access<Boolean>().testTuple(_self, vm, label, width);
}

inline
bool  TypedRichNode<Boolean>::testLabel(VM vm, class mozart::RichNode label) {
  return _self.access<Boolean>().testLabel(_self, vm, label);
}

inline
bool  TypedRichNode<Boolean>::value() {
  return _self.access<Boolean>().value();
}

inline
bool  TypedRichNode<Boolean>::equals(VM vm, class mozart::RichNode right) {
  return _self.access<Boolean>().equals(vm, right);
}

inline
int  TypedRichNode<Boolean>::compareFeatures(VM vm, class mozart::RichNode right) {
  return _self.access<Boolean>().compareFeatures(vm, right);
}

inline
atom_t  TypedRichNode<Boolean>::getPrintName(VM vm) {
  return _self.access<Boolean>().getPrintName(vm);
}

inline
bool  TypedRichNode<Boolean>::isName(VM vm) {
  return _self.access<Boolean>().isName(vm);
}

inline
class mozart::UnstableNode  TypedRichNode<Boolean>::serialize(VM vm, SE se) {
  return _self.access<Boolean>().serialize(vm, se);
}

inline
void  TypedRichNode<Boolean>::printReprToStream(VM vm, std::ostream & out, int depth, int width) {
  _self.access<Boolean>().printReprToStream(vm, out, depth, width);
}
