
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

StaticArray<class mozart::UnstableNode> TypedRichNode<Object>::getElementsArray() {
  return _self.access<Object>().getElementsArray();
}

class mozart::UnstableNode& TypedRichNode<Object>::getElements(size_t i) {
  return _self.access<Object>().getElements(i);
}

inline
class mozart::Space *  TypedRichNode<Object>::home() {
  return _self.access<Object>().home();
}

inline
size_t  TypedRichNode<Object>::getArraySizeImpl() {
  return _self.access<Object>().getArraySizeImpl();
}

inline
class mozart::StableNode *  TypedRichNode<Object>::getFeaturesRecord() {
  return _self.access<Object>().getFeaturesRecord();
}

inline
bool  TypedRichNode<Object>::lookupFeature(VM vm, class mozart::RichNode feature, nullable<class mozart::UnstableNode &> value) {
  return _self.access<Object>().lookupFeature(vm, feature, value);
}

inline
bool  TypedRichNode<Object>::lookupFeature(VM vm, nativeint feature, nullable<class mozart::UnstableNode &> value) {
  return _self.access<Object>().lookupFeature(vm, feature, value);
}

inline
bool  TypedRichNode<Object>::isChunk(VM vm) {
  return _self.access<Object>().isChunk(vm);
}

inline
bool  TypedRichNode<Object>::isObject(VM vm) {
  return _self.access<Object>().isObject(vm);
}

inline
class mozart::UnstableNode  TypedRichNode<Object>::getClass(VM vm) {
  return _self.access<Object>().getClass(vm);
}

inline
class mozart::UnstableNode  TypedRichNode<Object>::attrGet(VM vm, class mozart::RichNode attribute) {
  return _self.access<Object>().attrGet(_self, vm, attribute);
}

inline
void  TypedRichNode<Object>::attrPut(VM vm, class mozart::RichNode attribute, class mozart::RichNode value) {
  _self.access<Object>().attrPut(_self, vm, attribute, value);
}

inline
class mozart::UnstableNode  TypedRichNode<Object>::attrExchange(VM vm, class mozart::RichNode attribute, class mozart::RichNode newValue) {
  return _self.access<Object>().attrExchange(_self, vm, attribute, newValue);
}

inline
bool  TypedRichNode<Object>::isCallable(VM vm) {
  return _self.access<Object>().isCallable(vm);
}

inline
bool  TypedRichNode<Object>::isProcedure(VM vm) {
  return _self.access<Object>().isProcedure(vm);
}

inline
size_t  TypedRichNode<Object>::procedureArity(VM vm) {
  return _self.access<Object>().procedureArity(_self, vm);
}

inline
void  TypedRichNode<Object>::getCallInfo(VM vm, size_t & arity, ProgramCounter & start, size_t & Xcount, StaticArray<class mozart::StableNode> & Gs, StaticArray<class mozart::StableNode> & Ks) {
  _self.access<Object>().getCallInfo(_self, vm, arity, start, Xcount, Gs, Ks);
}

inline
void  TypedRichNode<Object>::getDebugInfo(VM vm, atom_t & printName, class mozart::UnstableNode & debugData) {
  _self.access<Object>().getDebugInfo(vm, printName, debugData);
}

inline
void  TypedRichNode<Object>::printReprToStream(VM vm, std::ostream & out, int depth, int width) {
  _self.access<Object>().printReprToStream(vm, out, depth, width);
}
