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
  StaticArray<mozart::StableNode> getElementsArray();

  inline
  mozart::StableNode& getElements(size_t i);

  inline
  mozart::Space * home();

  inline
  size_t getArraySizeImpl();

  inline
  mozart::atom_t getPrintName(mozart::VM vm);

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
  void printReprToStream(mozart::VM vm, std::ostream & out, int depth, int width);

  inline
  mozart::UnstableNode serialize(mozart::VM vm, mozart::SE se);

  inline
  mozart::GlobalNode * globalize(mozart::VM vm);

  inline
  void setUUID(mozart::VM vm, const mozart::UUID & uuid);
};
