template <>
class TypeInfoOf<Arity>: public TypeInfo {

  static constexpr UUID uuid() {
    return UUID();
  }
public:
  TypeInfoOf() : TypeInfo("Arity", uuid(), false, false, false, sbStructural, 0) {}

  static const TypeInfoOf<Arity>* const instance() {
    return &RawType<Arity>::rawType;
  }

  static Type type() {
    return Type(instance());
  }

  atom_t getTypeAtom(VM vm) const {
    return Arity::getTypeAtom(vm);
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
class TypedRichNode<Arity>: public BaseTypedRichNode {
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
  class mozart::StableNode * getLabel();

  inline
  size_t getWidth();

  inline
  class mozart::StableNode * getElement(size_t index);

  inline
  bool equals(VM vm, class mozart::RichNode right, class mozart::WalkStack & stack);

  inline
  bool lookupFeature(VM vm, class mozart::RichNode feature, size_t & offset);

  inline
  void printReprToStream(VM vm, std::ostream & out, int depth, int width);

  inline
  class mozart::UnstableNode serialize(VM vm, SE se);
};
