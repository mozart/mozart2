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
  bool equals(mozart::VM vm, mozart::RichNode right);

  inline
  mozart::atom_t getPrintName(mozart::VM vm);

  inline
  bool isBuiltin(mozart::VM vm);

  inline
  void callBuiltin(mozart::VM vm, size_t argc, mozart::UnstableNode ** args);

  template <class ... Args> 
  inline
  void callBuiltin(mozart::VM vm, Args &&... args);

  inline
  builtins::BaseBuiltin * getBuiltin(mozart::VM vm);

  inline
  bool isCallable(mozart::VM vm);

  inline
  bool isProcedure(mozart::VM vm);

  inline
  size_t procedureArity(mozart::VM vm);

  inline
  void getCallInfo(mozart::VM vm, size_t & arity, mozart::ProgramCounter & start, size_t & Xcount, StaticArray<mozart::StableNode> & Gs, StaticArray<mozart::StableNode> & Ks);

  inline
  void getDebugInfo(mozart::VM vm, mozart::atom_t & printName, mozart::UnstableNode & debugData);

  inline
  mozart::UnstableNode serialize(mozart::VM vm, mozart::SE se);

  inline
  void printReprToStream(mozart::VM vm, std::ostream & out, int depth, int width);
};
