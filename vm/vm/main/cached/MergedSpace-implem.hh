
void TypeInfoOf<MergedSpace>::gCollect(GC gc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.make<MergedSpace>(gc->vm, gc, from.access<MergedSpace>());
}

void TypeInfoOf<MergedSpace>::gCollect(GC gc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.make<MergedSpace>(gc->vm, gc, from.access<MergedSpace>());
}

void TypeInfoOf<MergedSpace>::sClone(SC sc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.init(sc->vm, from);
}

void TypeInfoOf<MergedSpace>::sClone(SC sc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.init(sc->vm, from);
}

inline
bool  TypedRichNode<MergedSpace>::isSpace(mozart::VM vm) {
  return _self.access<MergedSpace>().isSpace(vm);
}

inline
mozart::UnstableNode  TypedRichNode<MergedSpace>::askSpace(mozart::VM vm) {
  return _self.access<MergedSpace>().askSpace(vm);
}

inline
mozart::UnstableNode  TypedRichNode<MergedSpace>::askVerboseSpace(mozart::VM vm) {
  return _self.access<MergedSpace>().askVerboseSpace(vm);
}

inline
mozart::UnstableNode  TypedRichNode<MergedSpace>::mergeSpace(mozart::VM vm) {
  return _self.access<MergedSpace>().mergeSpace(vm);
}

inline
void  TypedRichNode<MergedSpace>::commitSpace(mozart::VM vm, mozart::RichNode value) {
  _self.access<MergedSpace>().commitSpace(vm, value);
}

inline
mozart::UnstableNode  TypedRichNode<MergedSpace>::cloneSpace(mozart::VM vm) {
  return _self.access<MergedSpace>().cloneSpace(vm);
}

inline
void  TypedRichNode<MergedSpace>::killSpace(mozart::VM vm) {
  _self.access<MergedSpace>().killSpace(vm);
}
