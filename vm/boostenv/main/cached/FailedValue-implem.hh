
void TypeInfoOf<FailedValue>::printReprToStream(VM vm, RichNode self, std::ostream& out,
                    int depth, int width) const {
  assert(self.is<FailedValue>());
  self.as<FailedValue>().printReprToStream(vm, out, depth, width);
}

void TypeInfoOf<FailedValue>::gCollect(GC gc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.make<FailedValue>(gc->vm, gc, from.access<FailedValue>());
}

void TypeInfoOf<FailedValue>::gCollect(GC gc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.make<FailedValue>(gc->vm, gc, from.access<FailedValue>());
}

void TypeInfoOf<FailedValue>::sClone(SC sc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.init(sc->vm, from);
}

void TypeInfoOf<FailedValue>::sClone(SC sc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.init(sc->vm, from);
}

inline
mozart::StableNode *  TypedRichNode<FailedValue>::getUnderlying() {
  return _self.access<FailedValue>().getUnderlying();
}

inline
void  TypedRichNode<FailedValue>::raiseUnderlying(mozart::VM vm) {
  _self.access<FailedValue>().raiseUnderlying(vm);
}

inline
void  TypedRichNode<FailedValue>::addToSuspendList(mozart::VM vm, mozart::RichNode variable) {
  _self.access<FailedValue>().addToSuspendList(vm, variable);
}

inline
bool  TypedRichNode<FailedValue>::isNeeded(mozart::VM vm) {
  return _self.access<FailedValue>().isNeeded(vm);
}

inline
void  TypedRichNode<FailedValue>::markNeeded(mozart::VM vm) {
  _self.access<FailedValue>().markNeeded(vm);
}

inline
void  TypedRichNode<FailedValue>::bind(mozart::VM vm, mozart::RichNode src) {
  _self.access<FailedValue>().bind(vm, src);
}

inline
void  TypedRichNode<FailedValue>::printReprToStream(mozart::VM vm, std::ostream & out, int depth, int width) {
  _self.access<FailedValue>().printReprToStream(vm, out, depth, width);
}
