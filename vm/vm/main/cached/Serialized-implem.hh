
void TypeInfoOf<Serialized>::gCollect(GC gc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.make<Serialized>(gc->vm, gc, from.access<Serialized>());
}

void TypeInfoOf<Serialized>::gCollect(GC gc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.make<Serialized>(gc->vm, gc, from.access<Serialized>());
}

void TypeInfoOf<Serialized>::sClone(SC sc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.init(sc->vm, from);
}

void TypeInfoOf<Serialized>::sClone(SC sc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.init(sc->vm, from);
}

inline
mozart::nativeint  TypedRichNode<Serialized>::n() {
  return _self.access<Serialized>().n();
}
