
void TypeInfoOf<ReadOnlyVariable>::printReprToStream(VM vm, RichNode self, std::ostream& out,
                    int depth, int width) const {
  assert(self.is<ReadOnlyVariable>());
  self.as<ReadOnlyVariable>().printReprToStream(vm, out, depth, width);
}

void TypeInfoOf<ReadOnlyVariable>::gCollect(GC gc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.make<ReadOnlyVariable>(gc->vm, gc, from.access<ReadOnlyVariable>());
}

void TypeInfoOf<ReadOnlyVariable>::gCollect(GC gc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.make<ReadOnlyVariable>(gc->vm, gc, from.access<ReadOnlyVariable>());
}

void TypeInfoOf<ReadOnlyVariable>::sClone(SC sc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.init(sc->vm, from);
}

void TypeInfoOf<ReadOnlyVariable>::sClone(SC sc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.init(sc->vm, from);
}

inline
mozart::Space *  TypedRichNode<ReadOnlyVariable>::home() {
  return _self.access<ReadOnlyVariable>().home();
}

inline
void  TypedRichNode<ReadOnlyVariable>::addToSuspendList(mozart::VM vm, mozart::RichNode variable) {
  _self.access<ReadOnlyVariable>().addToSuspendList(vm, variable);
}

inline
bool  TypedRichNode<ReadOnlyVariable>::isNeeded(mozart::VM vm) {
  return _self.access<ReadOnlyVariable>().isNeeded(vm);
}

inline
void  TypedRichNode<ReadOnlyVariable>::markNeeded(mozart::VM vm) {
  _self.access<ReadOnlyVariable>().markNeeded(vm);
}

inline
void  TypedRichNode<ReadOnlyVariable>::bind(mozart::VM vm, mozart::RichNode src) {
  _self.access<ReadOnlyVariable>().bind(_self, vm, src);
}

inline
void  TypedRichNode<ReadOnlyVariable>::bindReadOnly(mozart::VM vm, mozart::RichNode src) {
  _self.access<ReadOnlyVariable>().bindReadOnly(_self, vm, src);
}

inline
void  TypedRichNode<ReadOnlyVariable>::printReprToStream(mozart::VM vm, std::ostream & out, int depth, int width) {
  _self.access<ReadOnlyVariable>().printReprToStream(vm, out, depth, width);
}
