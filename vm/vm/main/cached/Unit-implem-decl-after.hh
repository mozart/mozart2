template <>
class TypeInfoOf<Unit>: public TypeInfo {

  static constexpr UUID uuid() {
    return Unit::uuid;
  }
public:
  TypeInfoOf() : TypeInfo("Unit", uuid(), (! ::mozart::MemWord::requiresExternalMemory<struct mozart::unit_t>()), false, true, sbValue, 0) {}

  static const TypeInfoOf<Unit>* const instance() {
    return &RawType<Unit>::rawType;
  }

  static Type type() {
    return Type(instance());
  }

  atom_t getTypeAtom(VM vm) const {
    return Unit::getTypeAtom(vm);
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

  inline
  int compareFeatures(VM vm, RichNode lhs, RichNode rhs) const;
};

template <>
class TypedRichNode<Unit>: public BaseTypedRichNode {
public:
  explicit TypedRichNode(RichNode self) : BaseTypedRichNode(self) {}

  inline
  bool isLiteral(VM vm);

  inline
  bool lookupFeature(VM vm, class mozart::RichNode feature, nullable<class mozart::UnstableNode &> value);

  inline
  bool lookupFeature(VM vm, nativeint feature, nullable<class mozart::UnstableNode &> value);

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
  bool equals(VM vm, class mozart::RichNode right);

  inline
  int compareFeatures(VM vm, class mozart::RichNode right);

  inline
  atom_t getPrintName(VM vm);

  inline
  bool isName(VM vm);

  inline
  class mozart::UnstableNode serialize(VM vm, SE se);

  inline
  void printReprToStream(VM vm, std::ostream & out, int depth, int width);
};
