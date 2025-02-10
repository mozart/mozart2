
void TypeInfoOf<ReflectiveEntity>::printReprToStream(VM vm, RichNode self, std::ostream& out,
                    int depth, int width) const {
  assert(self.is<ReflectiveEntity>());
  self.as<ReflectiveEntity>().printReprToStream(vm, out, depth, width);
}

void TypeInfoOf<ReflectiveEntity>::gCollect(GC gc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.make<ReflectiveEntity>(gc->vm, gc, from.access<ReflectiveEntity>());
}

void TypeInfoOf<ReflectiveEntity>::gCollect(GC gc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.make<ReflectiveEntity>(gc->vm, gc, from.access<ReflectiveEntity>());
}

void TypeInfoOf<ReflectiveEntity>::sClone(SC sc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.init(sc->vm, from);
}

void TypeInfoOf<ReflectiveEntity>::sClone(SC sc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.init(sc->vm, from);
}

template <typename Label, typename ... Args> 
inline
bool  TypedRichNode<ReflectiveEntity>::reflectiveCall(mozart::VM vm, const char * identity, Label && label, Args &&... args) {
  return _self.access<ReflectiveEntity>().reflectiveCall<Label, Args... >(vm, identity, std::forward<Label>(label), std::forward<Args>(args)...);
}

inline
void  TypedRichNode<ReflectiveEntity>::printReprToStream(mozart::VM vm, std::ostream & out, int depth, int width) {
  _self.access<ReflectiveEntity>().printReprToStream(vm, out, depth, width);
}
