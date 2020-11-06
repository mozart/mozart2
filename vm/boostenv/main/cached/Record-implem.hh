
void TypeInfoOf<Record>::printReprToStream(VM vm, RichNode self, std::ostream& out,
                    int depth, int width) const {
  assert(self.is<Record>());
  self.as<Record>().printReprToStream(vm, out, depth, width);
}

UnstableNode TypeInfoOf<Record>::serialize(VM vm, SE s, RichNode from) const {
  assert(from.is<Record>());
  return from.as<Record>().serialize(vm, s);
}

void TypeInfoOf<Record>::gCollect(GC gc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.make<Record>(gc->vm, from.as<Record>().getArraySize(), gc, from.access<Record>());
}

void TypeInfoOf<Record>::gCollect(GC gc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.make<Record>(gc->vm, from.as<Record>().getArraySize(), gc, from.access<Record>());
}

void TypeInfoOf<Record>::sClone(SC sc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.make<Record>(sc->vm, from.as<Record>().getArraySize(), sc, from.access<Record>());
}

void TypeInfoOf<Record>::sClone(SC sc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.make<Record>(sc->vm, from.as<Record>().getArraySize(), sc, from.access<Record>());
}

size_t TypedRichNode<Record>::getArraySize() {
  return _self.access<Record>().getArraySize();
}

StaticArray<mozart::StableNode> TypedRichNode<Record>::getElementsArray() {
  return _self.access<Record>().getElementsArray();
}

mozart::StableNode& TypedRichNode<Record>::getElements(size_t i) {
  return _self.access<Record>().getElements(i);
}

inline
size_t  TypedRichNode<Record>::getArraySizeImpl() {
  return _self.access<Record>().getArraySizeImpl();
}

inline
size_t  TypedRichNode<Record>::getWidth() {
  return _self.access<Record>().getWidth();
}

inline
mozart::StableNode *  TypedRichNode<Record>::getElement(size_t index) {
  return _self.access<Record>().getElement(index);
}

inline
bool  TypedRichNode<Record>::isRecord(mozart::VM vm) {
  return _self.access<Record>().isRecord(vm);
}

inline
size_t  TypedRichNode<Record>::width(mozart::VM vm) {
  return _self.access<Record>().width(vm);
}

inline
mozart::UnstableNode  TypedRichNode<Record>::arityList(mozart::VM vm) {
  return _self.access<Record>().arityList(vm);
}

inline
mozart::UnstableNode  TypedRichNode<Record>::waitOr(mozart::VM vm) {
  return _self.access<Record>().waitOr(vm);
}

inline
mozart::StableNode *  TypedRichNode<Record>::getArity() {
  return _self.access<Record>().getArity();
}

inline
bool  TypedRichNode<Record>::equals(mozart::VM vm, mozart::RichNode right, mozart::WalkStack & stack) {
  return _self.access<Record>().equals(vm, right, stack);
}

inline
bool  TypedRichNode<Record>::lookupFeature(mozart::VM vm, mozart::RichNode feature, nullable<mozart::UnstableNode &> value) {
  return _self.access<Record>().lookupFeature(vm, feature, value);
}

inline
bool  TypedRichNode<Record>::lookupFeature(mozart::VM vm, mozart::nativeint feature, nullable<mozart::UnstableNode &> value) {
  return _self.access<Record>().lookupFeature(vm, feature, value);
}

inline
bool  TypedRichNode<Record>::isTuple(mozart::VM vm) {
  return _self.access<Record>().isTuple(vm);
}

inline
mozart::UnstableNode  TypedRichNode<Record>::label(mozart::VM vm) {
  return _self.access<Record>().label(vm);
}

inline
mozart::UnstableNode  TypedRichNode<Record>::clone(mozart::VM vm) {
  return _self.access<Record>().clone(vm);
}

inline
bool  TypedRichNode<Record>::testRecord(mozart::VM vm, mozart::RichNode arity) {
  return _self.access<Record>().testRecord(vm, arity);
}

inline
bool  TypedRichNode<Record>::testTuple(mozart::VM vm, mozart::RichNode label, size_t width) {
  return _self.access<Record>().testTuple(vm, label, width);
}

inline
bool  TypedRichNode<Record>::testLabel(mozart::VM vm, mozart::RichNode label) {
  return _self.access<Record>().testLabel(vm, label);
}

inline
void  TypedRichNode<Record>::printReprToStream(mozart::VM vm, std::ostream & out, int depth, int width) {
  _self.access<Record>().printReprToStream(vm, out, depth, width);
}

inline
mozart::UnstableNode  TypedRichNode<Record>::serialize(mozart::VM vm, mozart::SE se) {
  return _self.access<Record>().serialize(vm, se);
}
