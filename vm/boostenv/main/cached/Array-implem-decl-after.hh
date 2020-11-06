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
  StaticArray<mozart::UnstableNode> getElementsArray();

  inline
  mozart::UnstableNode& getElements(size_t i);

  inline
  mozart::Space * home();

  inline
  bool lookupFeature(mozart::VM vm, mozart::RichNode feature, nullable<mozart::UnstableNode &> value);

  inline
  bool lookupFeature(mozart::VM vm, mozart::nativeint feature, nullable<mozart::UnstableNode &> value);

  inline
  size_t getArraySizeImpl();

  inline
  size_t getWidth();

  inline
  mozart::nativeint getLow();

  inline
  mozart::nativeint getHigh();

  inline
  void dotAssign(mozart::VM vm, mozart::RichNode feature, mozart::RichNode newValue);

  inline
  mozart::UnstableNode dotExchange(mozart::VM vm, mozart::RichNode feature, mozart::RichNode newValue);

  inline
  bool isArray(mozart::VM vm);

  inline
  mozart::UnstableNode arrayLow(mozart::VM vm);

  inline
  mozart::UnstableNode arrayHigh(mozart::VM vm);

  inline
  mozart::UnstableNode arrayGet(mozart::VM vm, mozart::RichNode index);

  inline
  void arrayPut(mozart::VM vm, mozart::RichNode index, mozart::RichNode value);

  inline
  mozart::UnstableNode arrayExchange(mozart::VM vm, mozart::RichNode index, mozart::RichNode newValue);

  inline
  void printReprToStream(mozart::VM vm, std::ostream & out, int depth, int width);
};
