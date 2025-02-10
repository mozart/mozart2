
void TypeInfoOf<VMPort>::printReprToStream(VM vm, RichNode self, std::ostream& out,
                    int depth, int width) const {
  assert(self.is<VMPort>());
  self.as<VMPort>().printReprToStream(vm, out, depth, width);
}

void TypeInfoOf<VMPort>::gCollect(GC gc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.make<VMPort>(gc->vm, gc, from.access<VMPort>());
}

void TypeInfoOf<VMPort>::gCollect(GC gc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.make<VMPort>(gc->vm, gc, from.access<VMPort>());
}

void TypeInfoOf<VMPort>::sClone(SC sc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.make<VMPort>(sc->vm, sc, from.access<VMPort>());
}

void TypeInfoOf<VMPort>::sClone(SC sc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.make<VMPort>(sc->vm, sc, from.access<VMPort>());
}

inline
mozart::VMIdentifier  TypedRichNode<VMPort>::value() {
  return _self.access<VMPort>().value();
}

inline
bool  TypedRichNode<VMPort>::equals(mozart::VM vm, mozart::RichNode right) {
  return _self.access<VMPort>().equals(vm, right);
}

inline
bool  TypedRichNode<VMPort>::isPort(mozart::VM vm) {
  return _self.access<VMPort>().isPort(vm);
}

inline
void  TypedRichNode<VMPort>::send(mozart::VM vm, mozart::RichNode value) {
  _self.access<VMPort>().send(vm, value);
}

inline
mozart::UnstableNode  TypedRichNode<VMPort>::sendReceive(mozart::VM vm, mozart::RichNode value) {
  return _self.access<VMPort>().sendReceive(vm, value);
}

inline
void  TypedRichNode<VMPort>::printReprToStream(mozart::VM vm, std::ostream & out, int depth, int width) {
  _self.access<VMPort>().printReprToStream(vm, out, depth, width);
}
