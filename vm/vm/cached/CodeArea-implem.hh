
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

StaticArray<class mozart::StableNode> TypedRichNode<CodeArea>::getElementsArray() {
  return _self.access<CodeArea>().getElementsArray();
}

class mozart::StableNode& TypedRichNode<CodeArea>::getElements(size_t i) {
  return _self.access<CodeArea>().getElements(i);
}

inline
size_t  TypedRichNode<CodeArea>::getArraySizeImpl() {
  return _self.access<CodeArea>().getArraySizeImpl();
}

inline
bool  TypedRichNode<CodeArea>::isCodeAreaProvider(VM vm) {
  return _self.access<CodeArea>().isCodeAreaProvider(vm);
}

inline
void  TypedRichNode<CodeArea>::getCodeAreaInfo(VM vm, size_t & arity, ProgramCounter & start, size_t & Xcount, StaticArray<class mozart::StableNode> & Ks) {
  _self.access<CodeArea>().getCodeAreaInfo(vm, arity, start, Xcount, Ks);
}

inline
void  TypedRichNode<CodeArea>::getCodeAreaDebugInfo(VM vm, atom_t & printName, class mozart::UnstableNode & debugData) {
  _self.access<CodeArea>().getCodeAreaDebugInfo(vm, printName, debugData);
}

inline
void  TypedRichNode<CodeArea>::printReprToStream(VM vm, std::ostream & out, int depth, int width) {
  _self.access<CodeArea>().printReprToStream(vm, out, depth, width);
}

inline
class mozart::UnstableNode  TypedRichNode<CodeArea>::serialize(VM vm, SE se) {
  return _self.access<CodeArea>().serialize(vm, se);
}

inline
class mozart::GlobalNode *  TypedRichNode<CodeArea>::globalize(VM vm) {
  return _self.access<CodeArea>().globalize(_self, vm);
}

inline
void  TypedRichNode<CodeArea>::setUUID(VM vm, const struct mozart::UUID & uuid) {
  _self.access<CodeArea>().setUUID(_self, vm, uuid);
}
