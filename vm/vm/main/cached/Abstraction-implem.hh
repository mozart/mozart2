
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

StaticArray<mozart::StableNode> TypedRichNode<Abstraction>::getElementsArray() {
  return _self.access<Abstraction>().getElementsArray();
}

mozart::StableNode& TypedRichNode<Abstraction>::getElements(size_t i) {
  return _self.access<Abstraction>().getElements(i);
}

inline
mozart::Space *  TypedRichNode<Abstraction>::home() {
  return _self.access<Abstraction>().home();
}

inline
size_t  TypedRichNode<Abstraction>::getArraySizeImpl() {
  return _self.access<Abstraction>().getArraySizeImpl();
}

inline
mozart::atom_t  TypedRichNode<Abstraction>::getPrintName(mozart::VM vm) {
  return _self.access<Abstraction>().getPrintName(vm);
}

inline
bool  TypedRichNode<Abstraction>::isCallable(mozart::VM vm) {
  return _self.access<Abstraction>().isCallable(vm);
}

inline
bool  TypedRichNode<Abstraction>::isProcedure(mozart::VM vm) {
  return _self.access<Abstraction>().isProcedure(vm);
}

inline
size_t  TypedRichNode<Abstraction>::procedureArity(mozart::VM vm) {
  return _self.access<Abstraction>().procedureArity(vm);
}

inline
void  TypedRichNode<Abstraction>::getCallInfo(mozart::VM vm, size_t & arity, mozart::ProgramCounter & start, size_t & Xcount, StaticArray<mozart::StableNode> & Gs, StaticArray<mozart::StableNode> & Ks) {
  _self.access<Abstraction>().getCallInfo(vm, arity, start, Xcount, Gs, Ks);
}

inline
void  TypedRichNode<Abstraction>::getDebugInfo(mozart::VM vm, mozart::atom_t & printName, mozart::UnstableNode & debugData) {
  _self.access<Abstraction>().getDebugInfo(vm, printName, debugData);
}

inline
void  TypedRichNode<Abstraction>::printReprToStream(mozart::VM vm, std::ostream & out, int depth, int width) {
  _self.access<Abstraction>().printReprToStream(vm, out, depth, width);
}

inline
mozart::UnstableNode  TypedRichNode<Abstraction>::serialize(mozart::VM vm, mozart::SE se) {
  return _self.access<Abstraction>().serialize(vm, se);
}

inline
mozart::GlobalNode *  TypedRichNode<Abstraction>::globalize(mozart::VM vm) {
  return _self.access<Abstraction>().globalize(_self, vm);
}

inline
void  TypedRichNode<Abstraction>::setUUID(mozart::VM vm, const mozart::UUID & uuid) {
  _self.access<Abstraction>().setUUID(_self, vm, uuid);
}
