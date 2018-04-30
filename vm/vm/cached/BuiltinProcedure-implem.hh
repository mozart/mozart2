
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
bool  TypedRichNode<BuiltinProcedure>::equals(VM vm, class mozart::RichNode right) {
  return _self.access<BuiltinProcedure>().equals(vm, right);
}

inline
atom_t  TypedRichNode<BuiltinProcedure>::getPrintName(VM vm) {
  return _self.access<BuiltinProcedure>().getPrintName(vm);
}

inline
bool  TypedRichNode<BuiltinProcedure>::isBuiltin(VM vm) {
  return _self.access<BuiltinProcedure>().isBuiltin(vm);
}

inline
void  TypedRichNode<BuiltinProcedure>::callBuiltin(VM vm, size_t argc, class mozart::UnstableNode ** args) {
  _self.access<BuiltinProcedure>().callBuiltin(vm, argc, args);
}

template <class ... Args> 
inline
void  TypedRichNode<BuiltinProcedure>::callBuiltin(VM vm, Args &&... args) {
  _self.access<BuiltinProcedure>().callBuiltin<Args... >(vm, std::forward<Args>(args)...);
}

inline
builtins::BaseBuiltin *  TypedRichNode<BuiltinProcedure>::getBuiltin(VM vm) {
  return _self.access<BuiltinProcedure>().getBuiltin(vm);
}

inline
bool  TypedRichNode<BuiltinProcedure>::isCallable(VM vm) {
  return _self.access<BuiltinProcedure>().isCallable(vm);
}

inline
bool  TypedRichNode<BuiltinProcedure>::isProcedure(VM vm) {
  return _self.access<BuiltinProcedure>().isProcedure(vm);
}

inline
size_t  TypedRichNode<BuiltinProcedure>::procedureArity(VM vm) {
  return _self.access<BuiltinProcedure>().procedureArity(vm);
}

inline
void  TypedRichNode<BuiltinProcedure>::getCallInfo(VM vm, size_t & arity, ProgramCounter & start, size_t & Xcount, StaticArray<class mozart::StableNode> & Gs, StaticArray<class mozart::StableNode> & Ks) {
  _self.access<BuiltinProcedure>().getCallInfo(_self, vm, arity, start, Xcount, Gs, Ks);
}

inline
void  TypedRichNode<BuiltinProcedure>::getDebugInfo(VM vm, atom_t & printName, class mozart::UnstableNode & debugData) {
  _self.access<BuiltinProcedure>().getDebugInfo(_self, vm, printName, debugData);
}

inline
class mozart::UnstableNode  TypedRichNode<BuiltinProcedure>::serialize(VM vm, SE se) {
  return _self.access<BuiltinProcedure>().serialize(vm, se);
}

inline
void  TypedRichNode<BuiltinProcedure>::printReprToStream(VM vm, std::ostream & out, int depth, int width) {
  _self.access<BuiltinProcedure>().printReprToStream(vm, out, depth, width);
}
