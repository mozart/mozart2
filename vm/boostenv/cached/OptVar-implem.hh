
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
class mozart::Space *  TypedRichNode<OptVar>::home() {
  return _self.access<OptVar>().home();
}

inline
void  TypedRichNode<OptVar>::addToSuspendList(VM vm, class mozart::RichNode variable) {
  _self.access<OptVar>().addToSuspendList(_self, vm, variable);
}

inline
bool  TypedRichNode<OptVar>::isNeeded(VM vm) {
  return _self.access<OptVar>().isNeeded(vm);
}

inline
void  TypedRichNode<OptVar>::markNeeded(VM vm) {
  _self.access<OptVar>().markNeeded(_self, vm);
}

inline
void  TypedRichNode<OptVar>::bind(VM vm, class mozart::UnstableNode && src) {
  _self.access<OptVar>().bind(_self, vm, src);
}

inline
void  TypedRichNode<OptVar>::bind(VM vm, class mozart::RichNode src) {
  _self.access<OptVar>().bind(_self, vm, src);
}

inline
void  TypedRichNode<OptVar>::printReprToStream(VM vm, std::ostream & out, int depth, int width) {
  _self.access<OptVar>().printReprToStream(vm, out, depth, width);
}
