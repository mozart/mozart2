template <>
class TypeInfoOf<Array>: public TypeInfo {

  static constexpr UUID uuid() {
    return UUID();
  }
public:
  TypeInfoOf() : TypeInfo("Array", uuid(), false, false, false, sbTokenEq, 0) {}

  static const TypeInfoOf<Array>* const instance() {
    return &RawType<Array>::rawType;
  }

  static Type type() {
    return Type(instance());
  }

  atom_t getTypeAtom(VM vm) const {
    return Array::getTypeAtom(vm);
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
class TypedRichNode<Array>: public BaseTypedRichNode {
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
  bool lookupFeature(VM vm, class mozart::RichNode feature, nullable<class mozart::UnstableNode &> value);

  inline
  bool lookupFeature(VM vm, nativeint feature, nullable<class mozart::UnstableNode &> value);

  inline
  size_t getArraySizeImpl();

  inline
  size_t getWidth();

  inline
  nativeint getLow();

  inline
  nativeint getHigh();

  inline
  void dotAssign(VM vm, class mozart::RichNode feature, class mozart::RichNode newValue);

  inline
  class mozart::UnstableNode dotExchange(VM vm, class mozart::RichNode feature, class mozart::RichNode newValue);

  inline
  bool isArray(VM vm);

  inline
  class mozart::UnstableNode arrayLow(VM vm);

  inline
  class mozart::UnstableNode arrayHigh(VM vm);

  inline
  class mozart::UnstableNode arrayGet(VM vm, class mozart::RichNode index);

  inline
  void arrayPut(VM vm, class mozart::RichNode index, class mozart::RichNode value);

  inline
  class mozart::UnstableNode arrayExchange(VM vm, class mozart::RichNode index, class mozart::RichNode newValue);

  inline
  void printReprToStream(VM vm, std::ostream & out, int depth, int width);
};
