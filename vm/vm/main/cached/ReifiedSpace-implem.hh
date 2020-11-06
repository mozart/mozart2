
void TypeInfoOf<ReifiedSpace>::gCollect(GC gc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.make<ReifiedSpace>(gc->vm, gc, from.access<ReifiedSpace>());
}

void TypeInfoOf<ReifiedSpace>::gCollect(GC gc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.make<ReifiedSpace>(gc->vm, gc, from.access<ReifiedSpace>());
}

void TypeInfoOf<ReifiedSpace>::sClone(SC sc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  if (from.as<ReifiedSpace>().home()->shouldBeCloned()) {
    to.make<ReifiedSpace>(sc->vm, sc, from.access<ReifiedSpace>());
  } else {
    to.init(sc->vm, from);
  }
}

void TypeInfoOf<ReifiedSpace>::sClone(SC sc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  if (from.as<ReifiedSpace>().home()->shouldBeCloned()) {
    to.make<ReifiedSpace>(sc->vm, sc, from.access<ReifiedSpace>());
  } else {
    to.init(sc->vm, from);
  }
}

inline
mozart::Space *  TypedRichNode<ReifiedSpace>::home() {
  return _self.access<ReifiedSpace>().home();
}

inline
mozart::Space *  TypedRichNode<ReifiedSpace>::getSpace() {
  return _self.access<ReifiedSpace>().getSpace();
}

inline
bool  TypedRichNode<ReifiedSpace>::isSpace(mozart::VM vm) {
  return _self.access<ReifiedSpace>().isSpace(vm);
}

inline
mozart::UnstableNode  TypedRichNode<ReifiedSpace>::askSpace(mozart::VM vm) {
  return _self.access<ReifiedSpace>().askSpace(_self, vm);
}

inline
mozart::UnstableNode  TypedRichNode<ReifiedSpace>::askVerboseSpace(mozart::VM vm) {
  return _self.access<ReifiedSpace>().askVerboseSpace(_self, vm);
}

inline
mozart::UnstableNode  TypedRichNode<ReifiedSpace>::mergeSpace(mozart::VM vm) {
  return _self.access<ReifiedSpace>().mergeSpace(_self, vm);
}

inline
void  TypedRichNode<ReifiedSpace>::commitSpace(mozart::VM vm, mozart::RichNode value) {
  _self.access<ReifiedSpace>().commitSpace(_self, vm, value);
}

inline
mozart::UnstableNode  TypedRichNode<ReifiedSpace>::cloneSpace(mozart::VM vm) {
  return _self.access<ReifiedSpace>().cloneSpace(_self, vm);
}

inline
void  TypedRichNode<ReifiedSpace>::killSpace(mozart::VM vm) {
  _self.access<ReifiedSpace>().killSpace(_self, vm);
}
