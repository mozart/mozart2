
void TypeInfoOf<Port>::printReprToStream(VM vm, RichNode self, std::ostream& out,
                    int depth, int width) const {
  assert(self.is<Port>());
  self.as<Port>().printReprToStream(vm, out, depth, width);
}

void TypeInfoOf<Port>::gCollect(GC gc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.make<Port>(gc->vm, gc, from.access<Port>());
}

void TypeInfoOf<Port>::gCollect(GC gc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.make<Port>(gc->vm, gc, from.access<Port>());
}

void TypeInfoOf<Port>::sClone(SC sc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  if (from.as<Port>().home()->shouldBeCloned()) {
    to.make<Port>(sc->vm, sc, from.access<Port>());
  } else {
    to.init(sc->vm, from);
  }
}

void TypeInfoOf<Port>::sClone(SC sc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  if (from.as<Port>().home()->shouldBeCloned()) {
    to.make<Port>(sc->vm, sc, from.access<Port>());
  } else {
    to.init(sc->vm, from);
  }
}

inline
mozart::Space *  TypedRichNode<Port>::home() {
  return _self.access<Port>().home();
}

inline
bool  TypedRichNode<Port>::isPort(mozart::VM vm) {
  return _self.access<Port>().isPort(vm);
}

inline
void  TypedRichNode<Port>::send(mozart::VM vm, mozart::RichNode value) {
  _self.access<Port>().send(vm, value);
}

inline
mozart::UnstableNode  TypedRichNode<Port>::sendReceive(mozart::VM vm, mozart::RichNode value) {
  return _self.access<Port>().sendReceive(vm, value);
}

inline
void  TypedRichNode<Port>::printReprToStream(mozart::VM vm, std::ostream & out, int depth, int width) {
  _self.access<Port>().printReprToStream(vm, out, depth, width);
}
