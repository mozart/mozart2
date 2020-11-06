
void TypeInfoOf<Cons>::printReprToStream(VM vm, RichNode self, std::ostream& out,
                    int depth, int width) const {
  assert(self.is<Cons>());
  self.as<Cons>().printReprToStream(vm, out, depth, width);
}

UnstableNode TypeInfoOf<Cons>::serialize(VM vm, SE s, RichNode from) const {
  assert(from.is<Cons>());
  return from.as<Cons>().serialize(vm, s);
}

void TypeInfoOf<Cons>::gCollect(GC gc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.make<Cons>(gc->vm, gc, from.access<Cons>());
}

void TypeInfoOf<Cons>::gCollect(GC gc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.make<Cons>(gc->vm, gc, from.access<Cons>());
}

void TypeInfoOf<Cons>::sClone(SC sc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.make<Cons>(sc->vm, sc, from.access<Cons>());
}

void TypeInfoOf<Cons>::sClone(SC sc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.make<Cons>(sc->vm, sc, from.access<Cons>());
}

inline
bool  TypedRichNode<Cons>::lookupFeature(mozart::VM vm, mozart::RichNode feature, nullable<mozart::UnstableNode &> value) {
  return _self.access<Cons>().lookupFeature(vm, feature, value);
}

inline
bool  TypedRichNode<Cons>::lookupFeature(mozart::VM vm, mozart::nativeint feature, nullable<mozart::UnstableNode &> value) {
  return _self.access<Cons>().lookupFeature(vm, feature, value);
}

inline
mozart::StableNode *  TypedRichNode<Cons>::getHead() {
  return _self.access<Cons>().getHead();
}

inline
mozart::StableNode *  TypedRichNode<Cons>::getTail() {
  return _self.access<Cons>().getTail();
}

inline
StaticArray<mozart::StableNode>  TypedRichNode<Cons>::getElementsArray() {
  return _self.access<Cons>().getElementsArray();
}

inline
bool  TypedRichNode<Cons>::equals(mozart::VM vm, mozart::RichNode right, mozart::WalkStack & stack) {
  return _self.access<Cons>().equals(vm, right, stack);
}

inline
bool  TypedRichNode<Cons>::isRecord(mozart::VM vm) {
  return _self.access<Cons>().isRecord(vm);
}

inline
bool  TypedRichNode<Cons>::isTuple(mozart::VM vm) {
  return _self.access<Cons>().isTuple(vm);
}

inline
mozart::UnstableNode  TypedRichNode<Cons>::label(mozart::VM vm) {
  return _self.access<Cons>().label(vm);
}

inline
size_t  TypedRichNode<Cons>::width(mozart::VM vm) {
  return _self.access<Cons>().width(vm);
}

inline
mozart::UnstableNode  TypedRichNode<Cons>::arityList(mozart::VM vm) {
  return _self.access<Cons>().arityList(vm);
}

inline
mozart::UnstableNode  TypedRichNode<Cons>::clone(mozart::VM vm) {
  return _self.access<Cons>().clone(vm);
}

inline
mozart::UnstableNode  TypedRichNode<Cons>::waitOr(mozart::VM vm) {
  return _self.access<Cons>().waitOr(vm);
}

inline
bool  TypedRichNode<Cons>::testRecord(mozart::VM vm, mozart::RichNode arity) {
  return _self.access<Cons>().testRecord(vm, arity);
}

inline
bool  TypedRichNode<Cons>::testTuple(mozart::VM vm, mozart::RichNode label, size_t width) {
  return _self.access<Cons>().testTuple(vm, label, width);
}

inline
bool  TypedRichNode<Cons>::testLabel(mozart::VM vm, mozart::RichNode label) {
  return _self.access<Cons>().testLabel(vm, label);
}

inline
void  TypedRichNode<Cons>::printReprToStream(mozart::VM vm, std::ostream & out, int depth, int width) {
  _self.access<Cons>().printReprToStream(vm, out, depth, width);
}

inline
bool  TypedRichNode<Cons>::hasListRepr(mozart::VM vm, int depth) {
  return _self.access<Cons>().hasListRepr(vm, depth);
}

inline
mozart::UnstableNode  TypedRichNode<Cons>::serialize(mozart::VM vm, mozart::SE se) {
  return _self.access<Cons>().serialize(vm, se);
}
