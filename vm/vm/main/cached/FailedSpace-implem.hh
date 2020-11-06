
void TypeInfoOf<FailedSpace>::gCollect(GC gc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.make<FailedSpace>(gc->vm, gc, from.access<FailedSpace>());
}

void TypeInfoOf<FailedSpace>::gCollect(GC gc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.make<FailedSpace>(gc->vm, gc, from.access<FailedSpace>());
}

void TypeInfoOf<FailedSpace>::sClone(SC sc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.init(sc->vm, from);
}

void TypeInfoOf<FailedSpace>::sClone(SC sc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.init(sc->vm, from);
}

inline
bool  TypedRichNode<FailedSpace>::isSpace(mozart::VM vm) {
  return _self.access<FailedSpace>().isSpace(vm);
}

inline
mozart::UnstableNode  TypedRichNode<FailedSpace>::askSpace(mozart::VM vm) {
  return _self.access<FailedSpace>().askSpace(vm);
}

inline
mozart::UnstableNode  TypedRichNode<FailedSpace>::askVerboseSpace(mozart::VM vm) {
  return _self.access<FailedSpace>().askVerboseSpace(vm);
}

inline
mozart::UnstableNode  TypedRichNode<FailedSpace>::mergeSpace(mozart::VM vm) {
  return _self.access<FailedSpace>().mergeSpace(vm);
}

inline
void  TypedRichNode<FailedSpace>::commitSpace(mozart::VM vm, mozart::RichNode value) {
  _self.access<FailedSpace>().commitSpace(vm, value);
}

inline
mozart::UnstableNode  TypedRichNode<FailedSpace>::cloneSpace(mozart::VM vm) {
  return _self.access<FailedSpace>().cloneSpace(vm);
}

inline
void  TypedRichNode<FailedSpace>::killSpace(mozart::VM vm) {
  _self.access<FailedSpace>().killSpace(vm);
}
