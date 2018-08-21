template <>
class TypeInfoOf<Abstraction>: public TypeInfo {

  static constexpr UUID uuid() {
    return UUID();
  }
public:
  TypeInfoOf() : TypeInfo("Abstraction", uuid(), false, false, false, sbTokenEq, 0) {}

  static const TypeInfoOf<Abstraction>* const instance() {
    return &RawType<Abstraction>::rawType;
  }

  static Type type() {
    return Type(instance());
  }

  atom_t getTypeAtom(VM vm) const {
    return Abstraction::getTypeAtom(vm);
  }

  inline
  void printReprToStream(VM vm, RichNode self, std::ostream& out,
                         int depth, int width) const;

  inline
  UnstableNode serialize(VM vm, SE s, RichNode from) const;

  inline
  GlobalNode* globalize(VM vm, RichNode from) const;

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
class TypedRichNode<Abstraction>: public BaseTypedRichNode {
public:
  explicit TypedRichNode(RichNode self) : BaseTypedRichNode(self) {}

  inline
  size_t getArraySize();

  inline
  StaticArray<class mozart::StableNode> getElementsArray();

  inline
  class mozart::StableNode& getElements(size_t i);

  inline
  class mozart::Space * home();

  inline
  size_t getArraySizeImpl();

  inline
  atom_t getPrintName(VM vm);

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
  void printReprToStream(VM vm, std::ostream & out, int depth, int width);

  inline
  class mozart::UnstableNode serialize(VM vm, SE se);

  inline
  class mozart::GlobalNode * globalize(VM vm);

  inline
  void setUUID(VM vm, const struct mozart::UUID & uuid);
};
