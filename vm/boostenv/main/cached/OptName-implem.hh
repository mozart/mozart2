
void TypeInfoOf<OptName>::printReprToStream(VM vm, RichNode self, std::ostream& out,
                    int depth, int width) const {
  assert(self.is<OptName>());
  self.as<OptName>().printReprToStream(vm, out, depth, width);
}

GlobalNode* TypeInfoOf<OptName>::globalize(VM vm, RichNode from) const {
  assert(from.is<OptName>());
  return from.as<OptName>().globalize(vm);
}

void TypeInfoOf<OptName>::gCollect(GC gc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.make<OptName>(gc->vm, gc, from.access<OptName>());
}

void TypeInfoOf<OptName>::gCollect(GC gc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.make<OptName>(gc->vm, gc, from.access<OptName>());
}

void TypeInfoOf<OptName>::sClone(SC sc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  if (from.as<OptName>().home()->shouldBeCloned()) {
    to.make<OptName>(sc->vm, sc, from.access<OptName>());
  } else {
    to.init(sc->vm, from);
  }
}

void TypeInfoOf<OptName>::sClone(SC sc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  if (from.as<OptName>().home()->shouldBeCloned()) {
    to.make<OptName>(sc->vm, sc, from.access<OptName>());
  } else {
    to.init(sc->vm, from);
  }
}

inline
mozart::Space *  TypedRichNode<OptName>::home() {
  return _self.access<OptName>().home();
}

inline
bool  TypedRichNode<OptName>::isLiteral(mozart::VM vm) {
  return _self.access<OptName>().isLiteral(vm);
}

inline
bool  TypedRichNode<OptName>::lookupFeature(mozart::VM vm, mozart::RichNode feature, nullable<mozart::UnstableNode &> value) {
  return _self.access<OptName>().lookupFeature(vm, feature, value);
}

inline
bool  TypedRichNode<OptName>::lookupFeature(mozart::VM vm, mozart::nativeint feature, nullable<mozart::UnstableNode &> value) {
  return _self.access<OptName>().lookupFeature(vm, feature, value);
}

inline
bool  TypedRichNode<OptName>::isRecord(mozart::VM vm) {
  return _self.access<OptName>().isRecord(vm);
}

inline
bool  TypedRichNode<OptName>::isTuple(mozart::VM vm) {
  return _self.access<OptName>().isTuple(vm);
}

inline
mozart::UnstableNode  TypedRichNode<OptName>::label(mozart::VM vm) {
  return _self.access<OptName>().label(_self, vm);
}

inline
size_t  TypedRichNode<OptName>::width(mozart::VM vm) {
  return _self.access<OptName>().width(vm);
}

inline
mozart::UnstableNode  TypedRichNode<OptName>::arityList(mozart::VM vm) {
  return _self.access<OptName>().arityList(vm);
}

inline
mozart::UnstableNode  TypedRichNode<OptName>::clone(mozart::VM vm) {
  return _self.access<OptName>().clone(_self, vm);
}

inline
mozart::UnstableNode  TypedRichNode<OptName>::waitOr(mozart::VM vm) {
  return _self.access<OptName>().waitOr(vm);
}

inline
bool  TypedRichNode<OptName>::testRecord(mozart::VM vm, mozart::RichNode arity) {
  return _self.access<OptName>().testRecord(vm, arity);
}

inline
bool  TypedRichNode<OptName>::testTuple(mozart::VM vm, mozart::RichNode label, size_t width) {
  return _self.access<OptName>().testTuple(_self, vm, label, width);
}

inline
bool  TypedRichNode<OptName>::testLabel(mozart::VM vm, mozart::RichNode label) {
  return _self.access<OptName>().testLabel(_self, vm, label);
}

inline
void  TypedRichNode<OptName>::makeFeature(mozart::VM vm) {
  _self.access<OptName>().makeFeature(_self, vm);
}

inline
bool  TypedRichNode<OptName>::isName(mozart::VM vm) {
  return _self.access<OptName>().isName(vm);
}

inline
mozart::GlobalNode *  TypedRichNode<OptName>::globalize(mozart::VM vm) {
  return _self.access<OptName>().globalize(_self, vm);
}

inline
void  TypedRichNode<OptName>::printReprToStream(mozart::VM vm, std::ostream & out, int depth, int width) {
  _self.access<OptName>().printReprToStream(vm, out, depth, width);
}
