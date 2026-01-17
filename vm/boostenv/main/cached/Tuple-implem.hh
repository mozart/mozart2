
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

StaticArray<mozart::StableNode> TypedRichNode<Tuple>::getElementsArray() {
  return _self.access<Tuple>().getElementsArray();
}

mozart::StableNode& TypedRichNode<Tuple>::getElements(size_t i) {
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
mozart::StableNode *  TypedRichNode<Tuple>::getElement(size_t index) {
  return _self.access<Tuple>().getElement(index);
}

inline
bool  TypedRichNode<Tuple>::isRecord(mozart::VM vm) {
  return _self.access<Tuple>().isRecord(vm);
}

inline
size_t  TypedRichNode<Tuple>::width(mozart::VM vm) {
  return _self.access<Tuple>().width(vm);
}

inline
mozart::UnstableNode  TypedRichNode<Tuple>::arityList(mozart::VM vm) {
  return _self.access<Tuple>().arityList(vm);
}

inline
mozart::UnstableNode  TypedRichNode<Tuple>::waitOr(mozart::VM vm) {
  return _self.access<Tuple>().waitOr(vm);
}

inline
bool  TypedRichNode<Tuple>::lookupFeature(mozart::VM vm, mozart::RichNode feature, nullable<mozart::UnstableNode &> value) {
  return _self.access<Tuple>().lookupFeature(vm, feature, value);
}

inline
bool  TypedRichNode<Tuple>::lookupFeature(mozart::VM vm, mozart::nativeint feature, nullable<mozart::UnstableNode &> value) {
  return _self.access<Tuple>().lookupFeature(vm, feature, value);
}

inline
mozart::StableNode *  TypedRichNode<Tuple>::getLabel() {
  return _self.access<Tuple>().getLabel();
}

inline
bool  TypedRichNode<Tuple>::equals(mozart::VM vm, mozart::RichNode right, mozart::WalkStack & stack) {
  return _self.access<Tuple>().equals(vm, right, stack);
}

inline
bool  TypedRichNode<Tuple>::isTuple(mozart::VM vm) {
  return _self.access<Tuple>().isTuple(vm);
}

inline
mozart::UnstableNode  TypedRichNode<Tuple>::label(mozart::VM vm) {
  return _self.access<Tuple>().label(vm);
}

inline
mozart::UnstableNode  TypedRichNode<Tuple>::clone(mozart::VM vm) {
  return _self.access<Tuple>().clone(vm);
}

inline
bool  TypedRichNode<Tuple>::testRecord(mozart::VM vm, mozart::RichNode arity) {
  return _self.access<Tuple>().testRecord(vm, arity);
}

inline
bool  TypedRichNode<Tuple>::testTuple(mozart::VM vm, mozart::RichNode label, size_t width) {
  return _self.access<Tuple>().testTuple(vm, label, width);
}

inline
bool  TypedRichNode<Tuple>::testLabel(mozart::VM vm, mozart::RichNode label) {
  return _self.access<Tuple>().testLabel(vm, label);
}

inline
void  TypedRichNode<Tuple>::printReprToStream(mozart::VM vm, std::ostream & out, int depth, int width) {
  _self.access<Tuple>().printReprToStream(vm, out, depth, width);
}

inline
bool  TypedRichNode<Tuple>::hasSharpRepr(mozart::VM vm, int depth) {
  return _self.access<Tuple>().hasSharpRepr(vm, depth);
}

inline
mozart::UnstableNode  TypedRichNode<Tuple>::serialize(mozart::VM vm, mozart::SE se) {
  return _self.access<Tuple>().serialize(vm, se);
}
