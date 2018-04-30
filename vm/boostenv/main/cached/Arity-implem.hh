
void TypeInfoOf<Arity>::printReprToStream(VM vm, RichNode self, std::ostream& out,
                    int depth, int width) const {
  assert(self.is<Arity>());
  self.as<Arity>().printReprToStream(vm, out, depth, width);
}

UnstableNode TypeInfoOf<Arity>::serialize(VM vm, SE s, RichNode from) const {
  assert(from.is<Arity>());
  return from.as<Arity>().serialize(vm, s);
}

void TypeInfoOf<Arity>::gCollect(GC gc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.make<Arity>(gc->vm, from.as<Arity>().getArraySize(), gc, from.access<Arity>());
}

void TypeInfoOf<Arity>::gCollect(GC gc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.make<Arity>(gc->vm, from.as<Arity>().getArraySize(), gc, from.access<Arity>());
}

void TypeInfoOf<Arity>::sClone(SC sc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.make<Arity>(sc->vm, from.as<Arity>().getArraySize(), sc, from.access<Arity>());
}

void TypeInfoOf<Arity>::sClone(SC sc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.make<Arity>(sc->vm, from.as<Arity>().getArraySize(), sc, from.access<Arity>());
}

size_t TypedRichNode<Arity>::getArraySize() {
  return _self.access<Arity>().getArraySize();
}

StaticArray<class mozart::StableNode> TypedRichNode<Arity>::getElementsArray() {
  return _self.access<Arity>().getElementsArray();
}

class mozart::StableNode& TypedRichNode<Arity>::getElements(size_t i) {
  return _self.access<Arity>().getElements(i);
}

inline
size_t  TypedRichNode<Arity>::getArraySizeImpl() {
  return _self.access<Arity>().getArraySizeImpl();
}

inline
class mozart::StableNode *  TypedRichNode<Arity>::getLabel() {
  return _self.access<Arity>().getLabel();
}

inline
size_t  TypedRichNode<Arity>::getWidth() {
  return _self.access<Arity>().getWidth();
}

inline
class mozart::StableNode *  TypedRichNode<Arity>::getElement(size_t index) {
  return _self.access<Arity>().getElement(index);
}

inline
bool  TypedRichNode<Arity>::equals(VM vm, class mozart::RichNode right, class mozart::WalkStack & stack) {
  return _self.access<Arity>().equals(vm, right, stack);
}

inline
bool  TypedRichNode<Arity>::lookupFeature(VM vm, class mozart::RichNode feature, size_t & offset) {
  return _self.access<Arity>().lookupFeature(vm, feature, offset);
}

inline
void  TypedRichNode<Arity>::printReprToStream(VM vm, std::ostream & out, int depth, int width) {
  _self.access<Arity>().printReprToStream(vm, out, depth, width);
}

inline
class mozart::UnstableNode  TypedRichNode<Arity>::serialize(VM vm, SE se) {
  return _self.access<Arity>().serialize(vm, se);
}
