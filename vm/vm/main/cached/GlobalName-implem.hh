
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
mozart::Space *  TypedRichNode<GlobalName>::home() {
  return _self.access<GlobalName>().home();
}

inline
bool  TypedRichNode<GlobalName>::isLiteral(mozart::VM vm) {
  return _self.access<GlobalName>().isLiteral(vm);
}

inline
bool  TypedRichNode<GlobalName>::lookupFeature(mozart::VM vm, mozart::RichNode feature, nullable<mozart::UnstableNode &> value) {
  return _self.access<GlobalName>().lookupFeature(vm, feature, value);
}

inline
bool  TypedRichNode<GlobalName>::lookupFeature(mozart::VM vm, mozart::nativeint feature, nullable<mozart::UnstableNode &> value) {
  return _self.access<GlobalName>().lookupFeature(vm, feature, value);
}

inline
bool  TypedRichNode<GlobalName>::isRecord(mozart::VM vm) {
  return _self.access<GlobalName>().isRecord(vm);
}

inline
bool  TypedRichNode<GlobalName>::isTuple(mozart::VM vm) {
  return _self.access<GlobalName>().isTuple(vm);
}

inline
mozart::UnstableNode  TypedRichNode<GlobalName>::label(mozart::VM vm) {
  return _self.access<GlobalName>().label(_self, vm);
}

inline
size_t  TypedRichNode<GlobalName>::width(mozart::VM vm) {
  return _self.access<GlobalName>().width(vm);
}

inline
mozart::UnstableNode  TypedRichNode<GlobalName>::arityList(mozart::VM vm) {
  return _self.access<GlobalName>().arityList(vm);
}

inline
mozart::UnstableNode  TypedRichNode<GlobalName>::clone(mozart::VM vm) {
  return _self.access<GlobalName>().clone(_self, vm);
}

inline
mozart::UnstableNode  TypedRichNode<GlobalName>::waitOr(mozart::VM vm) {
  return _self.access<GlobalName>().waitOr(vm);
}

inline
bool  TypedRichNode<GlobalName>::testRecord(mozart::VM vm, mozart::RichNode arity) {
  return _self.access<GlobalName>().testRecord(vm, arity);
}

inline
bool  TypedRichNode<GlobalName>::testTuple(mozart::VM vm, mozart::RichNode label, size_t width) {
  return _self.access<GlobalName>().testTuple(_self, vm, label, width);
}

inline
bool  TypedRichNode<GlobalName>::testLabel(mozart::VM vm, mozart::RichNode label) {
  return _self.access<GlobalName>().testLabel(_self, vm, label);
}

inline
const mozart::UUID &  TypedRichNode<GlobalName>::getUUID() {
  return _self.access<GlobalName>().getUUID();
}

inline
int  TypedRichNode<GlobalName>::compareFeatures(mozart::VM vm, mozart::RichNode right) {
  return _self.access<GlobalName>().compareFeatures(vm, right);
}

inline
bool  TypedRichNode<GlobalName>::isName(mozart::VM vm) {
  return _self.access<GlobalName>().isName(vm);
}

inline
mozart::GlobalNode *  TypedRichNode<GlobalName>::globalize(mozart::VM vm) {
  return _self.access<GlobalName>().globalize(_self, vm);
}

inline
void  TypedRichNode<GlobalName>::printReprToStream(mozart::VM vm, std::ostream & out, int depth, int width) {
  _self.access<GlobalName>().printReprToStream(vm, out, depth, width);
}
