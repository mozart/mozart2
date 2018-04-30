
void TypeInfoOf<GlobalName>::printReprToStream(VM vm, RichNode self, std::ostream& out,
                    int depth, int width) const {
  assert(self.is<GlobalName>());
  self.as<GlobalName>().printReprToStream(vm, out, depth, width);
}

GlobalNode* TypeInfoOf<GlobalName>::globalize(VM vm, RichNode from) const {
  assert(from.is<GlobalName>());
  return from.as<GlobalName>().globalize(vm);
}

void TypeInfoOf<GlobalName>::gCollect(GC gc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.make<GlobalName>(gc->vm, gc, from.access<GlobalName>());
}

void TypeInfoOf<GlobalName>::gCollect(GC gc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.make<GlobalName>(gc->vm, gc, from.access<GlobalName>());
}

void TypeInfoOf<GlobalName>::sClone(SC sc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  if (from.as<GlobalName>().home()->shouldBeCloned()) {
    to.make<GlobalName>(sc->vm, sc, from.access<GlobalName>());
  } else {
    to.init(sc->vm, from);
  }
}

void TypeInfoOf<GlobalName>::sClone(SC sc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  if (from.as<GlobalName>().home()->shouldBeCloned()) {
    to.make<GlobalName>(sc->vm, sc, from.access<GlobalName>());
  } else {
    to.init(sc->vm, from);
  }
}

int TypeInfoOf<GlobalName>::compareFeatures(VM vm, RichNode lhs, RichNode rhs) const {
  return lhs.as<GlobalName>().compareFeatures(vm, rhs);
}


inline
class mozart::Space *  TypedRichNode<GlobalName>::home() {
  return _self.access<GlobalName>().home();
}

inline
bool  TypedRichNode<GlobalName>::isLiteral(VM vm) {
  return _self.access<GlobalName>().isLiteral(vm);
}

inline
bool  TypedRichNode<GlobalName>::lookupFeature(VM vm, class mozart::RichNode feature, nullable<class mozart::UnstableNode &> value) {
  return _self.access<GlobalName>().lookupFeature(vm, feature, value);
}

inline
bool  TypedRichNode<GlobalName>::lookupFeature(VM vm, nativeint feature, nullable<class mozart::UnstableNode &> value) {
  return _self.access<GlobalName>().lookupFeature(vm, feature, value);
}

inline
bool  TypedRichNode<GlobalName>::isRecord(VM vm) {
  return _self.access<GlobalName>().isRecord(vm);
}

inline
bool  TypedRichNode<GlobalName>::isTuple(VM vm) {
  return _self.access<GlobalName>().isTuple(vm);
}

inline
class mozart::UnstableNode  TypedRichNode<GlobalName>::label(VM vm) {
  return _self.access<GlobalName>().label(_self, vm);
}

inline
size_t  TypedRichNode<GlobalName>::width(VM vm) {
  return _self.access<GlobalName>().width(vm);
}

inline
class mozart::UnstableNode  TypedRichNode<GlobalName>::arityList(VM vm) {
  return _self.access<GlobalName>().arityList(vm);
}

inline
class mozart::UnstableNode  TypedRichNode<GlobalName>::clone(VM vm) {
  return _self.access<GlobalName>().clone(_self, vm);
}

inline
class mozart::UnstableNode  TypedRichNode<GlobalName>::waitOr(VM vm) {
  return _self.access<GlobalName>().waitOr(vm);
}

inline
bool  TypedRichNode<GlobalName>::testRecord(VM vm, class mozart::RichNode arity) {
  return _self.access<GlobalName>().testRecord(vm, arity);
}

inline
bool  TypedRichNode<GlobalName>::testTuple(VM vm, class mozart::RichNode label, size_t width) {
  return _self.access<GlobalName>().testTuple(_self, vm, label, width);
}

inline
bool  TypedRichNode<GlobalName>::testLabel(VM vm, class mozart::RichNode label) {
  return _self.access<GlobalName>().testLabel(_self, vm, label);
}

inline
const struct mozart::UUID &  TypedRichNode<GlobalName>::getUUID() {
  return _self.access<GlobalName>().getUUID();
}

inline
int  TypedRichNode<GlobalName>::compareFeatures(VM vm, class mozart::RichNode right) {
  return _self.access<GlobalName>().compareFeatures(vm, right);
}

inline
bool  TypedRichNode<GlobalName>::isName(VM vm) {
  return _self.access<GlobalName>().isName(vm);
}

inline
class mozart::GlobalNode *  TypedRichNode<GlobalName>::globalize(VM vm) {
  return _self.access<GlobalName>().globalize(_self, vm);
}

inline
void  TypedRichNode<GlobalName>::printReprToStream(VM vm, std::ostream & out, int depth, int width) {
  _self.access<GlobalName>().printReprToStream(vm, out, depth, width);
}
