template <>
class TypeInfoOf<Cons>: public TypeInfo {

  static constexpr UUID uuid() {
    return UUID();
  }
public:
  TypeInfoOf() : TypeInfo("Cons", uuid(), false, false, false, sbStructural, 0) {}

  static const TypeInfoOf<Cons>* const instance() {
    return &RawType<Cons>::rawType;
  }

  static Type type() {
    return Type(instance());
  }

  atom_t getTypeAtom(VM vm) const {
    return Cons::getTypeAtom(vm);
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
class TypedRichNode<Cons>: public BaseTypedRichNode {
public:
  explicit TypedRichNode(RichNode self) : BaseTypedRichNode(self) {}

  inline
  bool lookupFeature(VM vm, class mozart::RichNode feature, nullable<class mozart::UnstableNode &> value);

  inline
  bool lookupFeature(VM vm, nativeint feature, nullable<class mozart::UnstableNode &> value);

  inline
  class mozart::StableNode * getHead();

  inline
  class mozart::StableNode * getTail();

  inline
  StaticArray<class mozart::StableNode> getElementsArray();

  inline
  bool equals(VM vm, class mozart::RichNode right, class mozart::WalkStack & stack);

  inline
  bool isRecord(VM vm);

  inline
  bool isTuple(VM vm);

  inline
  class mozart::UnstableNode label(VM vm);

  inline
  size_t width(VM vm);

  inline
  class mozart::UnstableNode arityList(VM vm);

  inline
  class mozart::UnstableNode clone(VM vm);

  inline
  class mozart::UnstableNode waitOr(VM vm);

  inline
  bool testRecord(VM vm, class mozart::RichNode arity);

  inline
  bool testTuple(VM vm, class mozart::RichNode label, size_t width);

  inline
  bool testLabel(VM vm, class mozart::RichNode label);

  inline
  void printReprToStream(VM vm, std::ostream & out, int depth, int width);

  inline
  bool hasListRepr(VM vm, int depth);

  inline
  class mozart::UnstableNode serialize(VM vm, SE se);
};
