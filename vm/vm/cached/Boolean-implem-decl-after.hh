template <>
class TypeInfoOf<Boolean>: public TypeInfo {

  static constexpr UUID uuid() {
    return Boolean::uuid;
  }
public:
  TypeInfoOf() : TypeInfo("Boolean", uuid(), (! ::mozart::MemWord::requiresExternalMemory<bool>()), false, true, sbValue, 0) {}

  static const TypeInfoOf<Boolean>* const instance() {
    return &RawType<Boolean>::rawType;
  }

  static Type type() {
    return Type(instance());
  }

  atom_t getTypeAtom(VM vm) const {
    return Boolean::getTypeAtom(vm);
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
class TypedRichNode<Boolean>: public BaseTypedRichNode {
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
  bool value();

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
