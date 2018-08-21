template <>
class TypeInfoOf<BuiltinProcedure>: public TypeInfo {

  static constexpr UUID uuid() {
    return UUID();
  }
public:
  TypeInfoOf() : TypeInfo("BuiltinProcedure", uuid(), (! ::mozart::MemWord::requiresExternalMemory<builtins::BaseBuiltin *>()), false, false, sbValue, 0) {}

  static const TypeInfoOf<BuiltinProcedure>* const instance() {
    return &RawType<BuiltinProcedure>::rawType;
  }

  static Type type() {
    return Type(instance());
  }

  atom_t getTypeAtom(VM vm) const {
    return BuiltinProcedure::getTypeAtom(vm);
  }

  inline
  void printReprToStream(VM vm, RichNode self, std::ostream& out,
                         int depth, int width) const;

  inline
  UnstableNode serialize(VM vm, SE s, RichNode from) const;

  inline
  void gCollect(GC gc, RichNode from, StableNode& to) const;

  inline
  void gCollect(GC gc, RichNode from, UnstableNode& to) const;

  inline
  void sClone(SC sc, RichNode from, StableNode& to) const;

  inline
  void sClone(SC sc, RichNode from, UnstableNode& to) const;
};

template <>
class TypedRichNode<BuiltinProcedure>: public BaseTypedRichNode {
public:
  explicit TypedRichNode(RichNode self) : BaseTypedRichNode(self) {}

  inline
  builtins::BaseBuiltin * value();

  inline
  size_t getArity();

  inline
  bool equals(VM vm, class mozart::RichNode right);

  inline
  atom_t getPrintName(VM vm);

  inline
  bool isBuiltin(VM vm);

  inline
  void callBuiltin(VM vm, size_t argc, class mozart::UnstableNode ** args);

  template <class ... Args> 
  inline
  void callBuiltin(VM vm, Args &&... args);

  inline
  builtins::BaseBuiltin * getBuiltin(VM vm);

  inline
  bool isCallable(VM vm);

  inline
  bool isProcedure(VM vm);

  inline
  size_t procedureArity(VM vm);

  inline
  void getCallInfo(VM vm, size_t & arity, ProgramCounter & start, size_t & Xcount, StaticArray<class mozart::StableNode> & Gs, StaticArray<class mozart::StableNode> & Ks);

  inline
  void getDebugInfo(VM vm, atom_t & printName, class mozart::UnstableNode & debugData);

  inline
  class mozart::UnstableNode serialize(VM vm, SE se);

  inline
  void printReprToStream(VM vm, std::ostream & out, int depth, int width);
};
