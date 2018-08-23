
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
  StableNode* stable = new (gc->vm) StableNode;
  to.make<Reference>(gc->vm, stable);
  stable->make<FailedValue>(gc->vm, gc, from.access<FailedValue>());
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
class mozart::StableNode *  TypedRichNode<FailedValue>::getUnderlying() {
  return _self.access<FailedValue>().getUnderlying();
}

inline
void  TypedRichNode<FailedValue>::raiseUnderlying(VM vm) {
  _self.access<FailedValue>().raiseUnderlying(vm);
}

inline
void  TypedRichNode<FailedValue>::addToSuspendList(VM vm, class mozart::RichNode variable) {
  _self.access<FailedValue>().addToSuspendList(vm, variable);
}

inline
bool  TypedRichNode<FailedValue>::isNeeded(VM vm) {
  return _self.access<FailedValue>().isNeeded(vm);
}

inline
void  TypedRichNode<FailedValue>::markNeeded(VM vm) {
  _self.access<FailedValue>().markNeeded(vm);
}

inline
void  TypedRichNode<FailedValue>::bind(VM vm, class mozart::RichNode src) {
  _self.access<FailedValue>().bind(vm, src);
}

inline
void  TypedRichNode<FailedValue>::printReprToStream(VM vm, std::ostream & out, int depth, int width) {
  _self.access<FailedValue>().printReprToStream(vm, out, depth, width);
}
