
void TypeInfoOf<OptVar>::printReprToStream(VM vm, RichNode self, std::ostream& out,
                    int depth, int width) const {
  assert(self.is<OptVar>());
  self.as<OptVar>().printReprToStream(vm, out, depth, width);
}

void TypeInfoOf<OptVar>::gCollect(GC gc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.make<OptVar>(gc->vm, gc, from.access<OptVar>());
}

void TypeInfoOf<OptVar>::gCollect(GC gc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.make<OptVar>(gc->vm, gc, from.access<OptVar>());
}

void TypeInfoOf<OptVar>::sClone(SC sc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  if (from.as<OptVar>().home()->shouldBeCloned()) {
    to.make<OptVar>(sc->vm, sc, from.access<OptVar>());
  } else {
    to.init(sc->vm, from);
  }
}

void TypeInfoOf<OptVar>::sClone(SC sc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  if (from.as<OptVar>().home()->shouldBeCloned()) {
    to.make<OptVar>(sc->vm, sc, from.access<OptVar>());
  } else {
    to.init(sc->vm, from);
  }
}

inline
mozart::Space *  TypedRichNode<OptVar>::home() {
  return _self.access<OptVar>().home();
}

inline
void  TypedRichNode<OptVar>::addToSuspendList(mozart::VM vm, mozart::RichNode variable) {
  _self.access<OptVar>().addToSuspendList(_self, vm, variable);
}

inline
bool  TypedRichNode<OptVar>::isNeeded(mozart::VM vm) {
  return _self.access<OptVar>().isNeeded(vm);
}

inline
void  TypedRichNode<OptVar>::markNeeded(mozart::VM vm) {
  _self.access<OptVar>().markNeeded(_self, vm);
}

inline
void  TypedRichNode<OptVar>::bind(mozart::VM vm, mozart::UnstableNode && src) {
  _self.access<OptVar>().bind(_self, vm, src);
}

inline
void  TypedRichNode<OptVar>::bind(mozart::VM vm, mozart::RichNode src) {
  _self.access<OptVar>().bind(_self, vm, src);
}

inline
void  TypedRichNode<OptVar>::printReprToStream(mozart::VM vm, std::ostream & out, int depth, int width) {
  _self.access<OptVar>().printReprToStream(vm, out, depth, width);
}
