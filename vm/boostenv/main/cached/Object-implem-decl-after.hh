template <>
class TypeInfoOf<Object>: public TypeInfo {

  static constexpr UUID uuid() {
    return UUID();
  }
public:
  TypeInfoOf() : TypeInfo("Object", uuid(), false, false, false, sbTokenEq, 0) {}

  static const TypeInfoOf<Object>* const instance() {
    return &RawType<Object>::rawType;
  }

  static Type type() {
    return Type(instance());
  }

  atom_t getTypeAtom(VM vm) const {
    return Object::getTypeAtom(vm);
  }

  inline
  void printReprToStream(VM vm, RichNode self, std::ostream& out,
                         int depth, int width) const;

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
class TypedRichNode<Object>: public BaseTypedRichNode {
public:
  explicit TypedRichNode(RichNode self) : BaseTypedRichNode(self) {}

  inline
  size_t getArraySize();

  inline
  StaticArray<class mozart::UnstableNode> getElementsArray();

  inline
  class mozart::UnstableNode& getElements(size_t i);

  inline
  class mozart::Space * home();

  inline
  size_t getArraySizeImpl();

  inline
  class mozart::StableNode * getFeaturesRecord();

  inline
  bool lookupFeature(VM vm, class mozart::RichNode feature, nullable<class mozart::UnstableNode &> value);

  inline
  bool lookupFeature(VM vm, nativeint feature, nullable<class mozart::UnstableNode &> value);

  inline
  bool isChunk(VM vm);

  inline
  bool isObject(VM vm);

  inline
  class mozart::UnstableNode getClass(VM vm);

  inline
  class mozart::UnstableNode attrGet(VM vm, class mozart::RichNode attribute);

  inline
  void attrPut(VM vm, class mozart::RichNode attribute, class mozart::RichNode value);

  inline
  class mozart::UnstableNode attrExchange(VM vm, class mozart::RichNode attribute, class mozart::RichNode newValue);

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
};
