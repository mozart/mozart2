
void TypeInfoOf<WeakReference>::gCollect(GC gc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.make<WeakReference>(gc->vm, gc, from.access<WeakReference>());
}

void TypeInfoOf<WeakReference>::gCollect(GC gc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.make<WeakReference>(gc->vm, gc, from.access<WeakReference>());
}

void TypeInfoOf<WeakReference>::sClone(SC sc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.init(sc->vm, from);
}

void TypeInfoOf<WeakReference>::sClone(SC sc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.init(sc->vm, from);
}

inline
mozart::StableNode *  TypedRichNode<WeakReference>::getUnderlying() {
  return _self.access<WeakReference>().getUnderlying();
}
