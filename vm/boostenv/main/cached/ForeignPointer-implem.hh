
void TypeInfoOf<ForeignPointer>::gCollect(GC gc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.make<ForeignPointer>(gc->vm, gc, from.access<ForeignPointer>());
}

void TypeInfoOf<ForeignPointer>::gCollect(GC gc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.make<ForeignPointer>(gc->vm, gc, from.access<ForeignPointer>());
}

void TypeInfoOf<ForeignPointer>::sClone(SC sc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.init(sc->vm, from);
}

void TypeInfoOf<ForeignPointer>::sClone(SC sc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.init(sc->vm, from);
}

template <class T> 
inline
std::shared_ptr<T>  TypedRichNode<ForeignPointer>::value() {
  return _self.access<ForeignPointer>().value<T>();
}

inline
std::shared_ptr<void>  TypedRichNode<ForeignPointer>::getVoidPointer() {
  return _self.access<ForeignPointer>().getVoidPointer();
}

inline
const std::type_info &  TypedRichNode<ForeignPointer>::pointerType() {
  return _self.access<ForeignPointer>().pointerType();
}

template <class T> 
inline
bool  TypedRichNode<ForeignPointer>::isPointer() {
  return _self.access<ForeignPointer>().isPointer<T>();
}
