
void TypeInfoOf<CodeArea>::printReprToStream(VM vm, RichNode self, std::ostream& out,
                    int depth, int width) const {
  assert(self.is<CodeArea>());
  self.as<CodeArea>().printReprToStream(vm, out, depth, width);
}

UnstableNode TypeInfoOf<CodeArea>::serialize(VM vm, SE s, RichNode from) const {
  assert(from.is<CodeArea>());
  return from.as<CodeArea>().serialize(vm, s);
}

GlobalNode* TypeInfoOf<CodeArea>::globalize(VM vm, RichNode from) const {
  assert(from.is<CodeArea>());
  return from.as<CodeArea>().globalize(vm);
}

void TypeInfoOf<CodeArea>::gCollect(GC gc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.make<CodeArea>(gc->vm, from.as<CodeArea>().getArraySize(), gc, from.access<CodeArea>());
}

void TypeInfoOf<CodeArea>::gCollect(GC gc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.make<CodeArea>(gc->vm, from.as<CodeArea>().getArraySize(), gc, from.access<CodeArea>());
}

void TypeInfoOf<CodeArea>::sClone(SC sc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.init(sc->vm, from);
}

void TypeInfoOf<CodeArea>::sClone(SC sc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.init(sc->vm, from);
}

size_t TypedRichNode<CodeArea>::getArraySize() {
  return _self.access<CodeArea>().getArraySize();
}

StaticArray<mozart::StableNode> TypedRichNode<CodeArea>::getElementsArray() {
  return _self.access<CodeArea>().getElementsArray();
}

mozart::StableNode& TypedRichNode<CodeArea>::getElements(size_t i) {
  return _self.access<CodeArea>().getElements(i);
}

inline
size_t  TypedRichNode<CodeArea>::getArraySizeImpl() {
  return _self.access<CodeArea>().getArraySizeImpl();
}

inline
bool  TypedRichNode<CodeArea>::isCodeAreaProvider(mozart::VM vm) {
  return _self.access<CodeArea>().isCodeAreaProvider(vm);
}

inline
void  TypedRichNode<CodeArea>::getCodeAreaInfo(mozart::VM vm, size_t & arity, mozart::ProgramCounter & start, size_t & Xcount, StaticArray<mozart::StableNode> & Ks) {
  _self.access<CodeArea>().getCodeAreaInfo(vm, arity, start, Xcount, Ks);
}

inline
void  TypedRichNode<CodeArea>::getCodeAreaDebugInfo(mozart::VM vm, mozart::atom_t & printName, mozart::UnstableNode & debugData) {
  _self.access<CodeArea>().getCodeAreaDebugInfo(vm, printName, debugData);
}

inline
void  TypedRichNode<CodeArea>::printReprToStream(mozart::VM vm, std::ostream & out, int depth, int width) {
  _self.access<CodeArea>().printReprToStream(vm, out, depth, width);
}

inline
mozart::UnstableNode  TypedRichNode<CodeArea>::serialize(mozart::VM vm, mozart::SE se) {
  return _self.access<CodeArea>().serialize(vm, se);
}

inline
mozart::GlobalNode *  TypedRichNode<CodeArea>::globalize(mozart::VM vm) {
  return _self.access<CodeArea>().globalize(_self, vm);
}

inline
void  TypedRichNode<CodeArea>::setUUID(mozart::VM vm, const mozart::UUID & uuid) {
  _self.access<CodeArea>().setUUID(_self, vm, uuid);
}
