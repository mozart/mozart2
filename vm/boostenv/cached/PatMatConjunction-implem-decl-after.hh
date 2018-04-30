template <>
class TypeInfoOf<PatMatConjunction>: public TypeInfo {

  static constexpr UUID uuid() {
    return UUID();
  }
public:
  TypeInfoOf() : TypeInfo("PatMatConjunction", uuid(), false, false, false, sbStructural, 0) {}

  static const TypeInfoOf<PatMatConjunction>* const instance() {
    return &RawType<PatMatConjunction>::rawType;
  }

  static Type type() {
    return Type(instance());
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
class TypedRichNode<PatMatConjunction>: public BaseTypedRichNode {
public:
  explicit TypedRichNode(RichNode self) : BaseTypedRichNode(self) {}

  inline
  size_t getArraySize();

  inline
  StaticArray<class mozart::StableNode> getElementsArray();

  inline
  class mozart::StableNode& getElements(size_t i);

  inline
  size_t getArraySizeImpl();

  inline
  size_t getCount();

  inline
  class mozart::StableNode * getElement(size_t index);

  inline
  bool equals(VM vm, class mozart::RichNode right, class mozart::WalkStack & stack);

  inline
  void printReprToStream(VM vm, std::ostream & out, int depth, int width);

  inline
  class mozart::UnstableNode serialize(VM vm, SE se);
};
