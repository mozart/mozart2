
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
class mozart::Space *  TypedRichNode<OptName>::home() {
  return _self.access<OptName>().home();
}

inline
bool  TypedRichNode<OptName>::isLiteral(VM vm) {
  return _self.access<OptName>().isLiteral(vm);
}

inline
bool  TypedRichNode<OptName>::lookupFeature(VM vm, class mozart::RichNode feature, nullable<class mozart::UnstableNode &> value) {
  return _self.access<OptName>().lookupFeature(vm, feature, value);
}

inline
bool  TypedRichNode<OptName>::lookupFeature(VM vm, nativeint feature, nullable<class mozart::UnstableNode &> value) {
  return _self.access<OptName>().lookupFeature(vm, feature, value);
}

inline
bool  TypedRichNode<OptName>::isRecord(VM vm) {
  return _self.access<OptName>().isRecord(vm);
}

inline
bool  TypedRichNode<OptName>::isTuple(VM vm) {
  return _self.access<OptName>().isTuple(vm);
}

inline
class mozart::UnstableNode  TypedRichNode<OptName>::label(VM vm) {
  return _self.access<OptName>().label(_self, vm);
}

inline
size_t  TypedRichNode<OptName>::width(VM vm) {
  return _self.access<OptName>().width(vm);
}

inline
class mozart::UnstableNode  TypedRichNode<OptName>::arityList(VM vm) {
  return _self.access<OptName>().arityList(vm);
}

inline
class mozart::UnstableNode  TypedRichNode<OptName>::clone(VM vm) {
  return _self.access<OptName>().clone(_self, vm);
}

inline
class mozart::UnstableNode  TypedRichNode<OptName>::waitOr(VM vm) {
  return _self.access<OptName>().waitOr(vm);
}

inline
bool  TypedRichNode<OptName>::testRecord(VM vm, class mozart::RichNode arity) {
  return _self.access<OptName>().testRecord(vm, arity);
}

inline
bool  TypedRichNode<OptName>::testTuple(VM vm, class mozart::RichNode label, size_t width) {
  return _self.access<OptName>().testTuple(_self, vm, label, width);
}

inline
bool  TypedRichNode<OptName>::testLabel(VM vm, class mozart::RichNode label) {
  return _self.access<OptName>().testLabel(_self, vm, label);
}

inline
void  TypedRichNode<OptName>::makeFeature(VM vm) {
  _self.access<OptName>().makeFeature(_self, vm);
}

inline
bool  TypedRichNode<OptName>::isName(VM vm) {
  return _self.access<OptName>().isName(vm);
}

inline
class mozart::GlobalNode *  TypedRichNode<OptName>::globalize(VM vm) {
  return _self.access<OptName>().globalize(_self, vm);
}

inline
void  TypedRichNode<OptName>::printReprToStream(VM vm, std::ostream & out, int depth, int width) {
  _self.access<OptName>().printReprToStream(vm, out, depth, width);
}
