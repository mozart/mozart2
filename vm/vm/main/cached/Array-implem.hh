
void TypeInfoOf<Array>::printReprToStream(VM vm, RichNode self, std::ostream& out,
                    int depth, int width) const {
  assert(self.is<Array>());
  self.as<Array>().printReprToStream(vm, out, depth, width);
}

void TypeInfoOf<Array>::gCollect(GC gc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.make<Array>(gc->vm, from.as<Array>().getArraySize(), gc, from.access<Array>());
}

void TypeInfoOf<Array>::gCollect(GC gc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.make<Array>(gc->vm, from.as<Array>().getArraySize(), gc, from.access<Array>());
}

void TypeInfoOf<Array>::sClone(SC sc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  if (from.as<Array>().home()->shouldBeCloned()) {
    to.make<Array>(sc->vm, from.as<Array>().getArraySize(), sc, from.access<Array>());
  } else {
    to.init(sc->vm, from);
  }
}

void TypeInfoOf<Array>::sClone(SC sc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  if (from.as<Array>().home()->shouldBeCloned()) {
    to.make<Array>(sc->vm, from.as<Array>().getArraySize(), sc, from.access<Array>());
  } else {
    to.init(sc->vm, from);
  }
}

size_t TypedRichNode<Array>::getArraySize() {
  return _self.access<Array>().getArraySize();
}

StaticArray<mozart::UnstableNode> TypedRichNode<Array>::getElementsArray() {
  return _self.access<Array>().getElementsArray();
}

mozart::UnstableNode& TypedRichNode<Array>::getElements(size_t i) {
  return _self.access<Array>().getElements(i);
}

inline
mozart::Space *  TypedRichNode<Array>::home() {
  return _self.access<Array>().home();
}

inline
bool  TypedRichNode<Array>::lookupFeature(mozart::VM vm, mozart::RichNode feature, nullable<mozart::UnstableNode &> value) {
  return _self.access<Array>().lookupFeature(vm, feature, value);
}

inline
bool  TypedRichNode<Array>::lookupFeature(mozart::VM vm, mozart::nativeint feature, nullable<mozart::UnstableNode &> value) {
  return _self.access<Array>().lookupFeature(vm, feature, value);
}

inline
size_t  TypedRichNode<Array>::getArraySizeImpl() {
  return _self.access<Array>().getArraySizeImpl();
}

inline
size_t  TypedRichNode<Array>::getWidth() {
  return _self.access<Array>().getWidth();
}

inline
mozart::nativeint  TypedRichNode<Array>::getLow() {
  return _self.access<Array>().getLow();
}

inline
mozart::nativeint  TypedRichNode<Array>::getHigh() {
  return _self.access<Array>().getHigh();
}

inline
void  TypedRichNode<Array>::dotAssign(mozart::VM vm, mozart::RichNode feature, mozart::RichNode newValue) {
  _self.access<Array>().dotAssign(_self, vm, feature, newValue);
}

inline
mozart::UnstableNode  TypedRichNode<Array>::dotExchange(mozart::VM vm, mozart::RichNode feature, mozart::RichNode newValue) {
  return _self.access<Array>().dotExchange(_self, vm, feature, newValue);
}

inline
bool  TypedRichNode<Array>::isArray(mozart::VM vm) {
  return _self.access<Array>().isArray(vm);
}

inline
mozart::UnstableNode  TypedRichNode<Array>::arrayLow(mozart::VM vm) {
  return _self.access<Array>().arrayLow(vm);
}

inline
mozart::UnstableNode  TypedRichNode<Array>::arrayHigh(mozart::VM vm) {
  return _self.access<Array>().arrayHigh(vm);
}

inline
mozart::UnstableNode  TypedRichNode<Array>::arrayGet(mozart::VM vm, mozart::RichNode index) {
  return _self.access<Array>().arrayGet(_self, vm, index);
}

inline
void  TypedRichNode<Array>::arrayPut(mozart::VM vm, mozart::RichNode index, mozart::RichNode value) {
  _self.access<Array>().arrayPut(_self, vm, index, value);
}

inline
mozart::UnstableNode  TypedRichNode<Array>::arrayExchange(mozart::VM vm, mozart::RichNode index, mozart::RichNode newValue) {
  return _self.access<Array>().arrayExchange(_self, vm, index, newValue);
}

inline
void  TypedRichNode<Array>::printReprToStream(mozart::VM vm, std::ostream & out, int depth, int width) {
  _self.access<Array>().printReprToStream(vm, out, depth, width);
}
