
void TypeInfoOf<NamedName>::printReprToStream(VM vm, RichNode self, std::ostream& out,
                    int depth, int width) const {
  assert(self.is<NamedName>());
  self.as<NamedName>().printReprToStream(vm, out, depth, width);
}

UnstableNode TypeInfoOf<NamedName>::serialize(VM vm, SE s, RichNode from) const {
  assert(from.is<NamedName>());
  return from.as<NamedName>().serialize(vm, s);
}

GlobalNode* TypeInfoOf<NamedName>::globalize(VM vm, RichNode from) const {
  assert(from.is<NamedName>());
  return from.as<NamedName>().globalize(vm);
}

void TypeInfoOf<NamedName>::gCollect(GC gc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.make<NamedName>(gc->vm, gc, from.access<NamedName>());
}

void TypeInfoOf<NamedName>::gCollect(GC gc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.make<NamedName>(gc->vm, gc, from.access<NamedName>());
}

void TypeInfoOf<NamedName>::sClone(SC sc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  if (from.as<NamedName>().home()->shouldBeCloned()) {
    to.make<NamedName>(sc->vm, sc, from.access<NamedName>());
  } else {
    to.init(sc->vm, from);
  }
}

void TypeInfoOf<NamedName>::sClone(SC sc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  if (from.as<NamedName>().home()->shouldBeCloned()) {
    to.make<NamedName>(sc->vm, sc, from.access<NamedName>());
  } else {
    to.init(sc->vm, from);
  }
}

int TypeInfoOf<NamedName>::compareFeatures(VM vm, RichNode lhs, RichNode rhs) const {
  return lhs.as<NamedName>().compareFeatures(vm, rhs);
}


inline
mozart::Space *  TypedRichNode<NamedName>::home() {
  return _self.access<NamedName>().home();
}

inline
bool  TypedRichNode<NamedName>::isLiteral(mozart::VM vm) {
  return _self.access<NamedName>().isLiteral(vm);
}

inline
bool  TypedRichNode<NamedName>::lookupFeature(mozart::VM vm, mozart::RichNode feature, nullable<mozart::UnstableNode &> value) {
  return _self.access<NamedName>().lookupFeature(vm, feature, value);
}

inline
bool  TypedRichNode<NamedName>::lookupFeature(mozart::VM vm, mozart::nativeint feature, nullable<mozart::UnstableNode &> value) {
  return _self.access<NamedName>().lookupFeature(vm, feature, value);
}

inline
bool  TypedRichNode<NamedName>::isRecord(mozart::VM vm) {
  return _self.access<NamedName>().isRecord(vm);
}

inline
bool  TypedRichNode<NamedName>::isTuple(mozart::VM vm) {
  return _self.access<NamedName>().isTuple(vm);
}

inline
mozart::UnstableNode  TypedRichNode<NamedName>::label(mozart::VM vm) {
  return _self.access<NamedName>().label(_self, vm);
}

inline
size_t  TypedRichNode<NamedName>::width(mozart::VM vm) {
  return _self.access<NamedName>().width(vm);
}

inline
mozart::UnstableNode  TypedRichNode<NamedName>::arityList(mozart::VM vm) {
  return _self.access<NamedName>().arityList(vm);
}

inline
mozart::UnstableNode  TypedRichNode<NamedName>::clone(mozart::VM vm) {
  return _self.access<NamedName>().clone(_self, vm);
}

inline
mozart::UnstableNode  TypedRichNode<NamedName>::waitOr(mozart::VM vm) {
  return _self.access<NamedName>().waitOr(vm);
}

inline
bool  TypedRichNode<NamedName>::testRecord(mozart::VM vm, mozart::RichNode arity) {
  return _self.access<NamedName>().testRecord(vm, arity);
}

inline
bool  TypedRichNode<NamedName>::testTuple(mozart::VM vm, mozart::RichNode label, size_t width) {
  return _self.access<NamedName>().testTuple(_self, vm, label, width);
}

inline
bool  TypedRichNode<NamedName>::testLabel(mozart::VM vm, mozart::RichNode label) {
  return _self.access<NamedName>().testLabel(_self, vm, label);
}

inline
const mozart::UUID &  TypedRichNode<NamedName>::getUUID() {
  return _self.access<NamedName>().getUUID();
}

inline
int  TypedRichNode<NamedName>::compareFeatures(mozart::VM vm, mozart::RichNode right) {
  return _self.access<NamedName>().compareFeatures(vm, right);
}

inline
mozart::atom_t  TypedRichNode<NamedName>::getPrintName(mozart::VM vm) {
  return _self.access<NamedName>().getPrintName(vm);
}

inline
bool  TypedRichNode<NamedName>::isName(mozart::VM vm) {
  return _self.access<NamedName>().isName(vm);
}

inline
mozart::UnstableNode  TypedRichNode<NamedName>::serialize(mozart::VM vm, mozart::SE se) {
  return _self.access<NamedName>().serialize(vm, se);
}

inline
mozart::GlobalNode *  TypedRichNode<NamedName>::globalize(mozart::VM vm) {
  return _self.access<NamedName>().globalize(_self, vm);
}

inline
void  TypedRichNode<NamedName>::printReprToStream(mozart::VM vm, std::ostream & out, int depth, int width) {
  _self.access<NamedName>().printReprToStream(vm, out, depth, width);
}
