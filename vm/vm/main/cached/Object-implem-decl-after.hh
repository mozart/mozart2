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
  StaticArray<mozart::UnstableNode> getElementsArray();

  inline
  mozart::UnstableNode& getElements(size_t i);

  inline
  mozart::Space * home();

  inline
  size_t getArraySizeImpl();

  inline
  mozart::StableNode * getFeaturesRecord();

  inline
  bool lookupFeature(mozart::VM vm, mozart::RichNode feature, nullable<mozart::UnstableNode &> value);

  inline
  bool lookupFeature(mozart::VM vm, mozart::nativeint feature, nullable<mozart::UnstableNode &> value);

  inline
  bool isChunk(mozart::VM vm);

  inline
  bool isObject(mozart::VM vm);

  inline
  mozart::UnstableNode getClass(mozart::VM vm);

  inline
  mozart::UnstableNode attrGet(mozart::VM vm, mozart::RichNode attribute);

  inline
  void attrPut(mozart::VM vm, mozart::RichNode attribute, mozart::RichNode value);

  inline
  mozart::UnstableNode attrExchange(mozart::VM vm, mozart::RichNode attribute, mozart::RichNode newValue);

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
};
