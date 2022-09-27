
void TypeInfoOf<ReflectiveVariable>::printReprToStream(VM vm, RichNode self, std::ostream& out,
                    int depth, int width) const {
  assert(self.is<ReflectiveVariable>());
  self.as<ReflectiveVariable>().printReprToStream(vm, out, depth, width);
}

void TypeInfoOf<ReflectiveVariable>::gCollect(GC gc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.make<ReflectiveVariable>(gc->vm, gc, from.access<ReflectiveVariable>());
}

void TypeInfoOf<ReflectiveVariable>::gCollect(GC gc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.make<ReflectiveVariable>(gc->vm, gc, from.access<ReflectiveVariable>());
}

void TypeInfoOf<ReflectiveVariable>::sClone(SC sc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.init(sc->vm, from);
}

void TypeInfoOf<ReflectiveVariable>::sClone(SC sc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.init(sc->vm, from);
}

inline
mozart::Space *  TypedRichNode<ReflectiveVariable>::home() {
  return _self.access<ReflectiveVariable>().home();
}

inline
void  TypedRichNode<ReflectiveVariable>::addToSuspendList(mozart::VM vm, mozart::RichNode variable) {
  _self.access<ReflectiveVariable>().addToSuspendList(vm, variable);
}

inline
bool  TypedRichNode<ReflectiveVariable>::isNeeded(mozart::VM vm) {
  return _self.access<ReflectiveVariable>().isNeeded(vm);
}

inline
void  TypedRichNode<ReflectiveVariable>::markNeeded(mozart::VM vm) {
  _self.access<ReflectiveVariable>().markNeeded(vm);
}

inline
void  TypedRichNode<ReflectiveVariable>::bind(mozart::VM vm, mozart::RichNode src) {
  _self.access<ReflectiveVariable>().bind(vm, src);
}

inline
void  TypedRichNode<ReflectiveVariable>::reflectiveBind(mozart::VM vm, mozart::RichNode src) {
  _self.access<ReflectiveVariable>().reflectiveBind(_self, vm, src);
}

inline
void  TypedRichNode<ReflectiveVariable>::bindReadOnly(mozart::VM vm, mozart::RichNode src) {
  _self.access<ReflectiveVariable>().bindReadOnly(vm, src);
}

inline
void  TypedRichNode<ReflectiveVariable>::printReprToStream(mozart::VM vm, std::ostream & out, int depth, int width) {
  _self.access<ReflectiveVariable>().printReprToStream(vm, out, depth, width);
}
