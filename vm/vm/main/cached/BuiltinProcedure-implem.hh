
void TypeInfoOf<BuiltinProcedure>::printReprToStream(VM vm, RichNode self, std::ostream& out,
                    int depth, int width) const {
  assert(self.is<BuiltinProcedure>());
  self.as<BuiltinProcedure>().printReprToStream(vm, out, depth, width);
}

UnstableNode TypeInfoOf<BuiltinProcedure>::serialize(VM vm, SE s, RichNode from) const {
  assert(from.is<BuiltinProcedure>());
  return from.as<BuiltinProcedure>().serialize(vm, s);
}

void TypeInfoOf<BuiltinProcedure>::gCollect(GC gc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.make<BuiltinProcedure>(gc->vm, gc, from.access<BuiltinProcedure>());
}

void TypeInfoOf<BuiltinProcedure>::gCollect(GC gc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.make<BuiltinProcedure>(gc->vm, gc, from.access<BuiltinProcedure>());
}

void TypeInfoOf<BuiltinProcedure>::sClone(SC sc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.make<BuiltinProcedure>(sc->vm, sc, from.access<BuiltinProcedure>());
}

void TypeInfoOf<BuiltinProcedure>::sClone(SC sc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.make<BuiltinProcedure>(sc->vm, sc, from.access<BuiltinProcedure>());
}

inline
builtins::BaseBuiltin *  TypedRichNode<BuiltinProcedure>::value() {
  return _self.access<BuiltinProcedure>().value();
}

inline
size_t  TypedRichNode<BuiltinProcedure>::getArity() {
  return _self.access<BuiltinProcedure>().getArity();
}

inline
bool  TypedRichNode<BuiltinProcedure>::equals(mozart::VM vm, mozart::RichNode right) {
  return _self.access<BuiltinProcedure>().equals(vm, right);
}

inline
mozart::atom_t  TypedRichNode<BuiltinProcedure>::getPrintName(mozart::VM vm) {
  return _self.access<BuiltinProcedure>().getPrintName(vm);
}

inline
bool  TypedRichNode<BuiltinProcedure>::isBuiltin(mozart::VM vm) {
  return _self.access<BuiltinProcedure>().isBuiltin(vm);
}

inline
void  TypedRichNode<BuiltinProcedure>::callBuiltin(mozart::VM vm, size_t argc, mozart::UnstableNode ** args) {
  _self.access<BuiltinProcedure>().callBuiltin(vm, argc, args);
}

template <class ... Args> 
inline
void  TypedRichNode<BuiltinProcedure>::callBuiltin(mozart::VM vm, Args &&... args) {
  _self.access<BuiltinProcedure>().callBuiltin<Args... >(vm, std::forward<Args>(args)...);
}

inline
builtins::BaseBuiltin *  TypedRichNode<BuiltinProcedure>::getBuiltin(mozart::VM vm) {
  return _self.access<BuiltinProcedure>().getBuiltin(vm);
}

inline
bool  TypedRichNode<BuiltinProcedure>::isCallable(mozart::VM vm) {
  return _self.access<BuiltinProcedure>().isCallable(vm);
}

inline
bool  TypedRichNode<BuiltinProcedure>::isProcedure(mozart::VM vm) {
  return _self.access<BuiltinProcedure>().isProcedure(vm);
}

inline
size_t  TypedRichNode<BuiltinProcedure>::procedureArity(mozart::VM vm) {
  return _self.access<BuiltinProcedure>().procedureArity(vm);
}

inline
void  TypedRichNode<BuiltinProcedure>::getCallInfo(mozart::VM vm, size_t & arity, mozart::ProgramCounter & start, size_t & Xcount, StaticArray<mozart::StableNode> & Gs, StaticArray<mozart::StableNode> & Ks) {
  _self.access<BuiltinProcedure>().getCallInfo(_self, vm, arity, start, Xcount, Gs, Ks);
}

inline
void  TypedRichNode<BuiltinProcedure>::getDebugInfo(mozart::VM vm, mozart::atom_t & printName, mozart::UnstableNode & debugData) {
  _self.access<BuiltinProcedure>().getDebugInfo(_self, vm, printName, debugData);
}

inline
mozart::UnstableNode  TypedRichNode<BuiltinProcedure>::serialize(mozart::VM vm, mozart::SE se) {
  return _self.access<BuiltinProcedure>().serialize(vm, se);
}

inline
void  TypedRichNode<BuiltinProcedure>::printReprToStream(mozart::VM vm, std::ostream & out, int depth, int width) {
  _self.access<BuiltinProcedure>().printReprToStream(vm, out, depth, width);
}
