template <>
class TypeInfoOf<Tuple>: public TypeInfo {

  static constexpr UUID uuid() {
    return UUID();
  }
public:
  TypeInfoOf() : TypeInfo("Tuple", uuid(), false, false, false, sbStructural, 0) {}

  static const TypeInfoOf<Tuple>* const instance() {
    return &RawType<Tuple>::rawType;
  }

  static Type type() {
    return Type(instance());
  }

  atom_t getTypeAtom(VM vm) const {
    return Tuple::getTypeAtom(vm);
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
class TypedRichNode<Tuple>: public BaseTypedRichNode {
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
  size_t getWidth();

  inline
  class mozart::StableNode * getElement(size_t index);

  inline
  bool isRecord(VM vm);

  inline
  size_t width(VM vm);

  inline
  class mozart::UnstableNode arityList(VM vm);

  inline
  class mozart::UnstableNode waitOr(VM vm);

  inline
  bool lookupFeature(VM vm, class mozart::RichNode feature, nullable<class mozart::UnstableNode &> value);

  inline
  bool lookupFeature(VM vm, nativeint feature, nullable<class mozart::UnstableNode &> value);

  inline
  class mozart::StableNode * getLabel();

  inline
  bool equals(VM vm, class mozart::RichNode right, class mozart::WalkStack & stack);

  inline
  bool isTuple(VM vm);

  inline
  class mozart::UnstableNode label(VM vm);

  inline
  class mozart::UnstableNode clone(VM vm);

  inline
  bool testRecord(VM vm, class mozart::RichNode arity);

  inline
  bool testTuple(VM vm, class mozart::RichNode label, size_t width);

  inline
  bool testLabel(VM vm, class mozart::RichNode label);

  inline
  void printReprToStream(VM vm, std::ostream & out, int depth, int width);

  inline
  bool hasSharpRepr(VM vm, int depth);

  inline
  class mozart::UnstableNode serialize(VM vm, SE se);
};
