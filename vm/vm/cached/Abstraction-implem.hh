
void TypeInfoOf<Abstraction>::printReprToStream(VM vm, RichNode self, std::ostream& out,
                    int depth, int width) const {
  assert(self.is<Abstraction>());
  self.as<Abstraction>().printReprToStream(vm, out, depth, width);
}

UnstableNode TypeInfoOf<Abstraction>::serialize(VM vm, SE s, RichNode from) const {
  assert(from.is<Abstraction>());
  return from.as<Abstraction>().serialize(vm, s);
}

GlobalNode* TypeInfoOf<Abstraction>::globalize(VM vm, RichNode from) const {
  assert(from.is<Abstraction>());
  return from.as<Abstraction>().globalize(vm);
}

void TypeInfoOf<Abstraction>::gCollect(GC gc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.make<Abstraction>(gc->vm, from.as<Abstraction>().getArraySize(), gc, from.access<Abstraction>());
}

void TypeInfoOf<Abstraction>::gCollect(GC gc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.make<Abstraction>(gc->vm, from.as<Abstraction>().getArraySize(), gc, from.access<Abstraction>());
}

void TypeInfoOf<Abstraction>::sClone(SC sc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  if (from.as<Abstraction>().home()->shouldBeCloned()) {
    to.make<Abstraction>(sc->vm, from.as<Abstraction>().getArraySize(), sc, from.access<Abstraction>());
  } else {
    to.init(sc->vm, from);
  }
}

void TypeInfoOf<Abstraction>::sClone(SC sc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  if (from.as<Abstraction>().home()->shouldBeCloned()) {
    to.make<Abstraction>(sc->vm, from.as<Abstraction>().getArraySize(), sc, from.access<Abstraction>());
  } else {
    to.init(sc->vm, from);
  }
}

size_t TypedRichNode<Abstraction>::getArraySize() {
  return _self.access<Abstraction>().getArraySize();
}

StaticArray<class mozart::StableNode> TypedRichNode<Abstraction>::getElementsArray() {
  return _self.access<Abstraction>().getElementsArray();
}

class mozart::StableNode& TypedRichNode<Abstraction>::getElements(size_t i) {
  return _self.access<Abstraction>().getElements(i);
}

inline
class mozart::Space *  TypedRichNode<Abstraction>::home() {
  return _self.access<Abstraction>().home();
}

inline
size_t  TypedRichNode<Abstraction>::getArraySizeImpl() {
  return _self.access<Abstraction>().getArraySizeImpl();
}

inline
atom_t  TypedRichNode<Abstraction>::getPrintName(VM vm) {
  return _self.access<Abstraction>().getPrintName(vm);
}

inline
bool  TypedRichNode<Abstraction>::isCallable(VM vm) {
  return _self.access<Abstraction>().isCallable(vm);
}

inline
bool  TypedRichNode<Abstraction>::isProcedure(VM vm) {
  return _self.access<Abstraction>().isProcedure(vm);
}

inline
size_t  TypedRichNode<Abstraction>::procedureArity(VM vm) {
  return _self.access<Abstraction>().procedureArity(vm);
}

inline
void  TypedRichNode<Abstraction>::getCallInfo(VM vm, size_t & arity, ProgramCounter & start, size_t & Xcount, StaticArray<class mozart::StableNode> & Gs, StaticArray<class mozart::StableNode> & Ks) {
  _self.access<Abstraction>().getCallInfo(vm, arity, start, Xcount, Gs, Ks);
}

inline
void  TypedRichNode<Abstraction>::getDebugInfo(VM vm, atom_t & printName, class mozart::UnstableNode & debugData) {
  _self.access<Abstraction>().getDebugInfo(vm, printName, debugData);
}

inline
void  TypedRichNode<Abstraction>::printReprToStream(VM vm, std::ostream & out, int depth, int width) {
  _self.access<Abstraction>().printReprToStream(vm, out, depth, width);
}

inline
class mozart::UnstableNode  TypedRichNode<Abstraction>::serialize(VM vm, SE se) {
  return _self.access<Abstraction>().serialize(vm, se);
}

inline
class mozart::GlobalNode *  TypedRichNode<Abstraction>::globalize(VM vm) {
  return _self.access<Abstraction>().globalize(_self, vm);
}

inline
void  TypedRichNode<Abstraction>::setUUID(VM vm, const struct mozart::UUID & uuid) {
  _self.access<Abstraction>().setUUID(_self, vm, uuid);
}
