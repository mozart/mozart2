template <>
class TypeInfoOf<CodeArea>: public TypeInfo {

  static constexpr UUID uuid() {
    return UUID();
  }
public:
  TypeInfoOf() : TypeInfo("CodeArea", uuid(), false, false, false, sbTokenEq, 0) {}

  static const TypeInfoOf<CodeArea>* const instance() {
    return &RawType<CodeArea>::rawType;
  }

  static Type type() {
    return Type(instance());
  }

  atom_t getTypeAtom(VM vm) const {
    return CodeArea::getTypeAtom(vm);
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
class TypedRichNode<CodeArea>: public BaseTypedRichNode {
public:
  explicit TypedRichNode(RichNode self) : BaseTypedRichNode(self) {}

  inline
  size_t getArraySize();

  inline
  StaticArray<mozart::StableNode> getElementsArray();

  inline
  mozart::StableNode& getElements(size_t i);

  inline
  size_t getArraySizeImpl();

  inline
  bool isCodeAreaProvider(mozart::VM vm);

  inline
  void getCodeAreaInfo(mozart::VM vm, size_t & arity, mozart::ProgramCounter & start, size_t & Xcount, StaticArray<mozart::StableNode> & Ks);

  inline
  void getCodeAreaDebugInfo(mozart::VM vm, mozart::atom_t & printName, mozart::UnstableNode & debugData);

  inline
  void printReprToStream(mozart::VM vm, std::ostream & out, int depth, int width);

  inline
  mozart::UnstableNode serialize(mozart::VM vm, mozart::SE se);

  inline
  mozart::GlobalNode * globalize(mozart::VM vm);

  inline
  void setUUID(mozart::VM vm, const mozart::UUID & uuid);
};
