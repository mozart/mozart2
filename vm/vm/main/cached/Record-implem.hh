
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

StaticArray<class mozart::StableNode> TypedRichNode<Record>::getElementsArray() {
  return _self.access<Record>().getElementsArray();
}

class mozart::StableNode& TypedRichNode<Record>::getElements(size_t i) {
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
class mozart::StableNode *  TypedRichNode<Record>::getElement(size_t index) {
  return _self.access<Record>().getElement(index);
}

inline
bool  TypedRichNode<Record>::isRecord(VM vm) {
  return _self.access<Record>().isRecord(vm);
}

inline
size_t  TypedRichNode<Record>::width(VM vm) {
  return _self.access<Record>().width(vm);
}

inline
class mozart::UnstableNode  TypedRichNode<Record>::arityList(VM vm) {
  return _self.access<Record>().arityList(vm);
}

inline
class mozart::UnstableNode  TypedRichNode<Record>::waitOr(VM vm) {
  return _self.access<Record>().waitOr(vm);
}

inline
class mozart::StableNode *  TypedRichNode<Record>::getArity() {
  return _self.access<Record>().getArity();
}

inline
bool  TypedRichNode<Record>::equals(VM vm, class mozart::RichNode right, class mozart::WalkStack & stack) {
  return _self.access<Record>().equals(vm, right, stack);
}

inline
bool  TypedRichNode<Record>::lookupFeature(VM vm, class mozart::RichNode feature, nullable<class mozart::UnstableNode &> value) {
  return _self.access<Record>().lookupFeature(vm, feature, value);
}

inline
bool  TypedRichNode<Record>::lookupFeature(VM vm, nativeint feature, nullable<class mozart::UnstableNode &> value) {
  return _self.access<Record>().lookupFeature(vm, feature, value);
}

inline
bool  TypedRichNode<Record>::isTuple(VM vm) {
  return _self.access<Record>().isTuple(vm);
}

inline
class mozart::UnstableNode  TypedRichNode<Record>::label(VM vm) {
  return _self.access<Record>().label(vm);
}

inline
class mozart::UnstableNode  TypedRichNode<Record>::clone(VM vm) {
  return _self.access<Record>().clone(vm);
}

inline
bool  TypedRichNode<Record>::testRecord(VM vm, class mozart::RichNode arity) {
  return _self.access<Record>().testRecord(vm, arity);
}

inline
bool  TypedRichNode<Record>::testTuple(VM vm, class mozart::RichNode label, size_t width) {
  return _self.access<Record>().testTuple(vm, label, width);
}

inline
bool  TypedRichNode<Record>::testLabel(VM vm, class mozart::RichNode label) {
  return _self.access<Record>().testLabel(vm, label);
}

inline
void  TypedRichNode<Record>::printReprToStream(VM vm, std::ostream & out, int depth, int width) {
  _self.access<Record>().printReprToStream(vm, out, depth, width);
}

inline
class mozart::UnstableNode  TypedRichNode<Record>::serialize(VM vm, SE se) {
  return _self.access<Record>().serialize(vm, se);
}
