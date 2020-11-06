
void TypeInfoOf<PatMatConjunction>::printReprToStream(VM vm, RichNode self, std::ostream& out,
                    int depth, int width) const {
  assert(self.is<PatMatConjunction>());
  self.as<PatMatConjunction>().printReprToStream(vm, out, depth, width);
}

UnstableNode TypeInfoOf<PatMatConjunction>::serialize(VM vm, SE s, RichNode from) const {
  assert(from.is<PatMatConjunction>());
  return from.as<PatMatConjunction>().serialize(vm, s);
}

void TypeInfoOf<PatMatConjunction>::gCollect(GC gc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.make<PatMatConjunction>(gc->vm, from.as<PatMatConjunction>().getArraySize(), gc, from.access<PatMatConjunction>());
}

void TypeInfoOf<PatMatConjunction>::gCollect(GC gc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.make<PatMatConjunction>(gc->vm, from.as<PatMatConjunction>().getArraySize(), gc, from.access<PatMatConjunction>());
}

void TypeInfoOf<PatMatConjunction>::sClone(SC sc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.make<PatMatConjunction>(sc->vm, from.as<PatMatConjunction>().getArraySize(), sc, from.access<PatMatConjunction>());
}

void TypeInfoOf<PatMatConjunction>::sClone(SC sc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.make<PatMatConjunction>(sc->vm, from.as<PatMatConjunction>().getArraySize(), sc, from.access<PatMatConjunction>());
}

size_t TypedRichNode<PatMatConjunction>::getArraySize() {
  return _self.access<PatMatConjunction>().getArraySize();
}

StaticArray<mozart::StableNode> TypedRichNode<PatMatConjunction>::getElementsArray() {
  return _self.access<PatMatConjunction>().getElementsArray();
}

mozart::StableNode& TypedRichNode<PatMatConjunction>::getElements(size_t i) {
  return _self.access<PatMatConjunction>().getElements(i);
}

inline
size_t  TypedRichNode<PatMatConjunction>::getArraySizeImpl() {
  return _self.access<PatMatConjunction>().getArraySizeImpl();
}

inline
size_t  TypedRichNode<PatMatConjunction>::getCount() {
  return _self.access<PatMatConjunction>().getCount();
}

inline
mozart::StableNode *  TypedRichNode<PatMatConjunction>::getElement(size_t index) {
  return _self.access<PatMatConjunction>().getElement(index);
}

inline
bool  TypedRichNode<PatMatConjunction>::equals(mozart::VM vm, mozart::RichNode right, mozart::WalkStack & stack) {
  return _self.access<PatMatConjunction>().equals(vm, right, stack);
}

inline
void  TypedRichNode<PatMatConjunction>::printReprToStream(mozart::VM vm, std::ostream & out, int depth, int width) {
  _self.access<PatMatConjunction>().printReprToStream(vm, out, depth, width);
}

inline
mozart::UnstableNode  TypedRichNode<PatMatConjunction>::serialize(mozart::VM vm, mozart::SE se) {
  return _self.access<PatMatConjunction>().serialize(vm, se);
}
