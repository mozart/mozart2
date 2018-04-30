
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
bool  TypedRichNode<FailedSpace>::isSpace(VM vm) {
  return _self.access<FailedSpace>().isSpace(vm);
}

inline
class mozart::UnstableNode  TypedRichNode<FailedSpace>::askSpace(VM vm) {
  return _self.access<FailedSpace>().askSpace(vm);
}

inline
class mozart::UnstableNode  TypedRichNode<FailedSpace>::askVerboseSpace(VM vm) {
  return _self.access<FailedSpace>().askVerboseSpace(vm);
}

inline
class mozart::UnstableNode  TypedRichNode<FailedSpace>::mergeSpace(VM vm) {
  return _self.access<FailedSpace>().mergeSpace(vm);
}

inline
void  TypedRichNode<FailedSpace>::commitSpace(VM vm, class mozart::RichNode value) {
  _self.access<FailedSpace>().commitSpace(vm, value);
}

inline
class mozart::UnstableNode  TypedRichNode<FailedSpace>::cloneSpace(VM vm) {
  return _self.access<FailedSpace>().cloneSpace(vm);
}

inline
void  TypedRichNode<FailedSpace>::killSpace(VM vm) {
  _self.access<FailedSpace>().killSpace(vm);
}
