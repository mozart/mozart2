
void TypeInfoOf<Serializer>::gCollect(GC gc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.make<Serializer>(gc->vm, gc, from.access<Serializer>());
}

void TypeInfoOf<Serializer>::gCollect(GC gc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.make<Serializer>(gc->vm, gc, from.access<Serializer>());
}

void TypeInfoOf<Serializer>::sClone(SC sc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.init(sc->vm, from);
}

void TypeInfoOf<Serializer>::sClone(SC sc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.init(sc->vm, from);
}

inline
mozart::UnstableNode  TypedRichNode<Serializer>::doSerialize(mozart::VM vm, mozart::RichNode todo) {
  return _self.access<Serializer>().doSerialize(vm, todo);
}
