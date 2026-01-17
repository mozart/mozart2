template <>
class TypeInfoOf<PatMatOpenRecord>: public TypeInfo {

  static constexpr UUID uuid() {
    return UUID();
  }
public:
  TypeInfoOf() : TypeInfo("PatMatOpenRecord", uuid(), false, false, false, sbTokenEq, 0) {}

  static const TypeInfoOf<PatMatOpenRecord>* const instance() {
    return &RawType<PatMatOpenRecord>::rawType;
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
class TypedRichNode<PatMatOpenRecord>: public BaseTypedRichNode {
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
  mozart::StableNode * getElement(size_t index);

  inline
  mozart::StableNode * getArity();

  inline
  void printReprToStream(mozart::VM vm, std::ostream & out, int depth, int width);

  inline
  mozart::UnstableNode serialize(mozart::VM vm, mozart::SE se);
};
