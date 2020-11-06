
void TypeInfoOf<ReadOnly>::printReprToStream(VM vm, RichNode self, std::ostream& out,
                    int depth, int width) const {
  assert(self.is<ReadOnly>());
  self.as<ReadOnly>().printReprToStream(vm, out, depth, width);
}

void TypeInfoOf<ReadOnly>::gCollect(GC gc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.make<ReadOnly>(gc->vm, gc, from.access<ReadOnly>());
}

void TypeInfoOf<ReadOnly>::gCollect(GC gc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.make<ReadOnly>(gc->vm, gc, from.access<ReadOnly>());
}

void TypeInfoOf<ReadOnly>::sClone(SC sc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.init(sc->vm, from);
}

void TypeInfoOf<ReadOnly>::sClone(SC sc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.init(sc->vm, from);
}

inline
mozart::StableNode *  TypedRichNode<ReadOnly>::getUnderlying() {
  return _self.access<ReadOnly>().getUnderlying();
}

inline
void  TypedRichNode<ReadOnly>::wakeUp(mozart::VM vm) {
  _self.access<ReadOnly>().wakeUp(_self, vm);
}

inline
bool  TypedRichNode<ReadOnly>::shouldWakeUpUnderSpace(mozart::VM vm, mozart::Space * space) {
  return _self.access<ReadOnly>().shouldWakeUpUnderSpace(vm, space);
}

inline
void  TypedRichNode<ReadOnly>::addToSuspendList(mozart::VM vm, mozart::RichNode variable) {
  _self.access<ReadOnly>().addToSuspendList(vm, variable);
}

inline
bool  TypedRichNode<ReadOnly>::isNeeded(mozart::VM vm) {
  return _self.access<ReadOnly>().isNeeded(vm);
}

inline
void  TypedRichNode<ReadOnly>::markNeeded(mozart::VM vm) {
  _self.access<ReadOnly>().markNeeded(vm);
}

inline
void  TypedRichNode<ReadOnly>::bind(mozart::VM vm, mozart::RichNode src) {
  _self.access<ReadOnly>().bind(vm, src);
}

inline
void  TypedRichNode<ReadOnly>::printReprToStream(mozart::VM vm, std::ostream & out, int depth, int width) {
  _self.access<ReadOnly>().printReprToStream(vm, out, depth, width);
}
