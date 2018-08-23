
void TypeInfoOf<Tuple>::printReprToStream(VM vm, RichNode self, std::ostream& out,
                    int depth, int width) const {
  assert(self.is<Tuple>());
  self.as<Tuple>().printReprToStream(vm, out, depth, width);
}

UnstableNode TypeInfoOf<Tuple>::serialize(VM vm, SE s, RichNode from) const {
  assert(from.is<Tuple>());
  return from.as<Tuple>().serialize(vm, s);
}

void TypeInfoOf<Tuple>::gCollect(GC gc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.make<Tuple>(gc->vm, from.as<Tuple>().getArraySize(), gc, from.access<Tuple>());
}

void TypeInfoOf<Tuple>::gCollect(GC gc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.make<Tuple>(gc->vm, from.as<Tuple>().getArraySize(), gc, from.access<Tuple>());
}

void TypeInfoOf<Tuple>::sClone(SC sc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.make<Tuple>(sc->vm, from.as<Tuple>().getArraySize(), sc, from.access<Tuple>());
}

void TypeInfoOf<Tuple>::sClone(SC sc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.make<Tuple>(sc->vm, from.as<Tuple>().getArraySize(), sc, from.access<Tuple>());
}

size_t TypedRichNode<Tuple>::getArraySize() {
  return _self.access<Tuple>().getArraySize();
}

StaticArray<class mozart::StableNode> TypedRichNode<Tuple>::getElementsArray() {
  return _self.access<Tuple>().getElementsArray();
}

class mozart::StableNode& TypedRichNode<Tuple>::getElements(size_t i) {
  return _self.access<Tuple>().getElements(i);
}

inline
size_t  TypedRichNode<Tuple>::getArraySizeImpl() {
  return _self.access<Tuple>().getArraySizeImpl();
}

inline
size_t  TypedRichNode<Tuple>::getWidth() {
  return _self.access<Tuple>().getWidth();
}

inline
class mozart::StableNode *  TypedRichNode<Tuple>::getElement(size_t index) {
  return _self.access<Tuple>().getElement(index);
}

inline
bool  TypedRichNode<Tuple>::isRecord(VM vm) {
  return _self.access<Tuple>().isRecord(vm);
}

inline
size_t  TypedRichNode<Tuple>::width(VM vm) {
  return _self.access<Tuple>().width(vm);
}

inline
class mozart::UnstableNode  TypedRichNode<Tuple>::arityList(VM vm) {
  return _self.access<Tuple>().arityList(vm);
}

inline
class mozart::UnstableNode  TypedRichNode<Tuple>::waitOr(VM vm) {
  return _self.access<Tuple>().waitOr(vm);
}

inline
bool  TypedRichNode<Tuple>::lookupFeature(VM vm, class mozart::RichNode feature, nullable<class mozart::UnstableNode &> value) {
  return _self.access<Tuple>().lookupFeature(vm, feature, value);
}

inline
bool  TypedRichNode<Tuple>::lookupFeature(VM vm, nativeint feature, nullable<class mozart::UnstableNode &> value) {
  return _self.access<Tuple>().lookupFeature(vm, feature, value);
}

inline
class mozart::StableNode *  TypedRichNode<Tuple>::getLabel() {
  return _self.access<Tuple>().getLabel();
}

inline
bool  TypedRichNode<Tuple>::equals(VM vm, class mozart::RichNode right, class mozart::WalkStack & stack) {
  return _self.access<Tuple>().equals(vm, right, stack);
}

inline
bool  TypedRichNode<Tuple>::isTuple(VM vm) {
  return _self.access<Tuple>().isTuple(vm);
}

inline
class mozart::UnstableNode  TypedRichNode<Tuple>::label(VM vm) {
  return _self.access<Tuple>().label(vm);
}

inline
class mozart::UnstableNode  TypedRichNode<Tuple>::clone(VM vm) {
  return _self.access<Tuple>().clone(vm);
}

inline
bool  TypedRichNode<Tuple>::testRecord(VM vm, class mozart::RichNode arity) {
  return _self.access<Tuple>().testRecord(vm, arity);
}

inline
bool  TypedRichNode<Tuple>::testTuple(VM vm, class mozart::RichNode label, size_t width) {
  return _self.access<Tuple>().testTuple(vm, label, width);
}

inline
bool  TypedRichNode<Tuple>::testLabel(VM vm, class mozart::RichNode label) {
  return _self.access<Tuple>().testLabel(vm, label);
}

inline
void  TypedRichNode<Tuple>::printReprToStream(VM vm, std::ostream & out, int depth, int width) {
  _self.access<Tuple>().printReprToStream(vm, out, depth, width);
}

inline
bool  TypedRichNode<Tuple>::hasSharpRepr(VM vm, int depth) {
  return _self.access<Tuple>().hasSharpRepr(vm, depth);
}

inline
class mozart::UnstableNode  TypedRichNode<Tuple>::serialize(VM vm, SE se) {
  return _self.access<Tuple>().serialize(vm, se);
}
