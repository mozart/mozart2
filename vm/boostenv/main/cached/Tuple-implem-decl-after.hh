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
  StaticArray<mozart::StableNode> getElementsArray();

  inline
  mozart::StableNode& getElements(size_t i);

  inline
  size_t getArraySizeImpl();

  inline
  size_t getWidth();

  inline
  mozart::StableNode * getElement(size_t index);

  inline
  bool isRecord(mozart::VM vm);

  inline
  size_t width(mozart::VM vm);

  inline
  mozart::UnstableNode arityList(mozart::VM vm);

  inline
  mozart::UnstableNode waitOr(mozart::VM vm);

  inline
  bool lookupFeature(mozart::VM vm, mozart::RichNode feature, nullable<mozart::UnstableNode &> value);

  inline
  bool lookupFeature(mozart::VM vm, mozart::nativeint feature, nullable<mozart::UnstableNode &> value);

  inline
  mozart::StableNode * getLabel();

  inline
  bool equals(mozart::VM vm, mozart::RichNode right, mozart::WalkStack & stack);

  inline
  bool isTuple(mozart::VM vm);

  inline
  mozart::UnstableNode label(mozart::VM vm);

  inline
  mozart::UnstableNode clone(mozart::VM vm);

  inline
  bool testRecord(mozart::VM vm, mozart::RichNode arity);

  inline
  bool testTuple(mozart::VM vm, mozart::RichNode label, size_t width);

  inline
  bool testLabel(mozart::VM vm, mozart::RichNode label);

  inline
  void printReprToStream(mozart::VM vm, std::ostream & out, int depth, int width);

  inline
  bool hasSharpRepr(mozart::VM vm, int depth);

  inline
  mozart::UnstableNode serialize(mozart::VM vm, mozart::SE se);
};
