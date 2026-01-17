
void TypeInfoOf<PatMatOpenRecord>::printReprToStream(VM vm, RichNode self, std::ostream& out,
                    int depth, int width) const {
  assert(self.is<PatMatOpenRecord>());
  self.as<PatMatOpenRecord>().printReprToStream(vm, out, depth, width);
}

UnstableNode TypeInfoOf<PatMatOpenRecord>::serialize(VM vm, SE s, RichNode from) const {
  assert(from.is<PatMatOpenRecord>());
  return from.as<PatMatOpenRecord>().serialize(vm, s);
}

void TypeInfoOf<PatMatOpenRecord>::gCollect(GC gc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.make<PatMatOpenRecord>(gc->vm, from.as<PatMatOpenRecord>().getArraySize(), gc, from.access<PatMatOpenRecord>());
}

void TypeInfoOf<PatMatOpenRecord>::gCollect(GC gc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.make<PatMatOpenRecord>(gc->vm, from.as<PatMatOpenRecord>().getArraySize(), gc, from.access<PatMatOpenRecord>());
}

void TypeInfoOf<PatMatOpenRecord>::sClone(SC sc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.init(sc->vm, from);
}

void TypeInfoOf<PatMatOpenRecord>::sClone(SC sc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.init(sc->vm, from);
}

size_t TypedRichNode<PatMatOpenRecord>::getArraySize() {
  return _self.access<PatMatOpenRecord>().getArraySize();
}

StaticArray<mozart::StableNode> TypedRichNode<PatMatOpenRecord>::getElementsArray() {
  return _self.access<PatMatOpenRecord>().getElementsArray();
}

mozart::StableNode& TypedRichNode<PatMatOpenRecord>::getElements(size_t i) {
  return _self.access<PatMatOpenRecord>().getElements(i);
}

inline
size_t  TypedRichNode<PatMatOpenRecord>::getArraySizeImpl() {
  return _self.access<PatMatOpenRecord>().getArraySizeImpl();
}

inline
mozart::StableNode *  TypedRichNode<PatMatOpenRecord>::getElement(size_t index) {
  return _self.access<PatMatOpenRecord>().getElement(index);
}

inline
mozart::StableNode *  TypedRichNode<PatMatOpenRecord>::getArity() {
  return _self.access<PatMatOpenRecord>().getArity();
}

inline
void  TypedRichNode<PatMatOpenRecord>::printReprToStream(mozart::VM vm, std::ostream & out, int depth, int width) {
  _self.access<PatMatOpenRecord>().printReprToStream(vm, out, depth, width);
}

inline
mozart::UnstableNode  TypedRichNode<PatMatOpenRecord>::serialize(mozart::VM vm, mozart::SE se) {
  return _self.access<PatMatOpenRecord>().serialize(vm, se);
}
