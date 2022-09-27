
void TypeInfoOf<Object>::printReprToStream(VM vm, RichNode self, std::ostream& out,
                    int depth, int width) const {
  assert(self.is<Object>());
  self.as<Object>().printReprToStream(vm, out, depth, width);
}

void TypeInfoOf<Object>::gCollect(GC gc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.make<Object>(gc->vm, from.as<Object>().getArraySize(), gc, from.access<Object>());
}

void TypeInfoOf<Object>::gCollect(GC gc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.make<Object>(gc->vm, from.as<Object>().getArraySize(), gc, from.access<Object>());
}

void TypeInfoOf<Object>::sClone(SC sc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  if (from.as<Object>().home()->shouldBeCloned()) {
    to.make<Object>(sc->vm, from.as<Object>().getArraySize(), sc, from.access<Object>());
  } else {
    to.init(sc->vm, from);
  }
}

void TypeInfoOf<Object>::sClone(SC sc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  if (from.as<Object>().home()->shouldBeCloned()) {
    to.make<Object>(sc->vm, from.as<Object>().getArraySize(), sc, from.access<Object>());
  } else {
    to.init(sc->vm, from);
  }
}

size_t TypedRichNode<Object>::getArraySize() {
  return _self.access<Object>().getArraySize();
}

StaticArray<mozart::UnstableNode> TypedRichNode<Object>::getElementsArray() {
  return _self.access<Object>().getElementsArray();
}

mozart::UnstableNode& TypedRichNode<Object>::getElements(size_t i) {
  return _self.access<Object>().getElements(i);
}

inline
mozart::Space *  TypedRichNode<Object>::home() {
  return _self.access<Object>().home();
}

inline
size_t  TypedRichNode<Object>::getArraySizeImpl() {
  return _self.access<Object>().getArraySizeImpl();
}

inline
mozart::StableNode *  TypedRichNode<Object>::getFeaturesRecord() {
  return _self.access<Object>().getFeaturesRecord();
}

inline
bool  TypedRichNode<Object>::lookupFeature(mozart::VM vm, mozart::RichNode feature, nullable<mozart::UnstableNode &> value) {
  return _self.access<Object>().lookupFeature(vm, feature, value);
}

inline
bool  TypedRichNode<Object>::lookupFeature(mozart::VM vm, mozart::nativeint feature, nullable<mozart::UnstableNode &> value) {
  return _self.access<Object>().lookupFeature(vm, feature, value);
}

inline
bool  TypedRichNode<Object>::isChunk(mozart::VM vm) {
  return _self.access<Object>().isChunk(vm);
}

inline
bool  TypedRichNode<Object>::isObject(mozart::VM vm) {
  return _self.access<Object>().isObject(vm);
}

inline
mozart::UnstableNode  TypedRichNode<Object>::getClass(mozart::VM vm) {
  return _self.access<Object>().getClass(vm);
}

inline
mozart::UnstableNode  TypedRichNode<Object>::attrGet(mozart::VM vm, mozart::RichNode attribute) {
  return _self.access<Object>().attrGet(_self, vm, attribute);
}

inline
void  TypedRichNode<Object>::attrPut(mozart::VM vm, mozart::RichNode attribute, mozart::RichNode value) {
  _self.access<Object>().attrPut(_self, vm, attribute, value);
}

inline
mozart::UnstableNode  TypedRichNode<Object>::attrExchange(mozart::VM vm, mozart::RichNode attribute, mozart::RichNode newValue) {
  return _self.access<Object>().attrExchange(_self, vm, attribute, newValue);
}

inline
bool  TypedRichNode<Object>::isCallable(mozart::VM vm) {
  return _self.access<Object>().isCallable(vm);
}

inline
bool  TypedRichNode<Object>::isProcedure(mozart::VM vm) {
  return _self.access<Object>().isProcedure(vm);
}

inline
size_t  TypedRichNode<Object>::procedureArity(mozart::VM vm) {
  return _self.access<Object>().procedureArity(_self, vm);
}

inline
void  TypedRichNode<Object>::getCallInfo(mozart::VM vm, size_t & arity, mozart::ProgramCounter & start, size_t & Xcount, StaticArray<mozart::StableNode> & Gs, StaticArray<mozart::StableNode> & Ks) {
  _self.access<Object>().getCallInfo(_self, vm, arity, start, Xcount, Gs, Ks);
}

inline
void  TypedRichNode<Object>::getDebugInfo(mozart::VM vm, mozart::atom_t & printName, mozart::UnstableNode & debugData) {
  _self.access<Object>().getDebugInfo(vm, printName, debugData);
}

inline
void  TypedRichNode<Object>::printReprToStream(mozart::VM vm, std::ostream & out, int depth, int width) {
  _self.access<Object>().printReprToStream(vm, out, depth, width);
}
