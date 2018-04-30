template <>
class TypeInfoOf<SmallInt>: public TypeInfo {

  static constexpr UUID uuid() {
    return SmallInt::uuid;
  }
public:
  TypeInfoOf() : TypeInfo("SmallInt", uuid(), (! ::mozart::MemWord::requiresExternalMemory<nativeint>()), false, true, sbValue, 0) {}

  static const TypeInfoOf<SmallInt>* const instance() {
    return &RawType<SmallInt>::rawType;
  }

  static Type type() {
    return Type(instance());
  }

  atom_t getTypeAtom(VM vm) const {
    return SmallInt::getTypeAtom(vm);
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

  inline
  int compareFeatures(VM vm, RichNode lhs, RichNode rhs) const;
};

template <>
class TypedRichNode<SmallInt>: public BaseTypedRichNode {
public:
  explicit TypedRichNode(RichNode self) : BaseTypedRichNode(self) {}

  inline
  nativeint value();

  inline
  bool equals(VM vm, class mozart::RichNode right);

  inline
  int compareFeatures(VM vm, class mozart::RichNode right);

  inline
  int compare(VM vm, class mozart::RichNode right);

  inline
  bool isNumber(VM vm);

  inline
  bool isInt(VM vm);

  inline
  bool isFloat(VM vm);

  inline
  class mozart::UnstableNode opposite(VM vm);

  inline
  class mozart::UnstableNode add(VM vm, class mozart::RichNode right);

  inline
  class mozart::UnstableNode add(VM vm, nativeint b);

  inline
  class mozart::UnstableNode subtract(VM vm, class mozart::RichNode right);

  inline
  class mozart::UnstableNode subtractValue(VM vm, nativeint b);

  inline
  class mozart::UnstableNode multiply(VM vm, class mozart::RichNode right);

  inline
  class mozart::UnstableNode multiplyValue(VM vm, nativeint b);

  inline
  class mozart::UnstableNode div(VM vm, class mozart::RichNode right);

  inline
  class mozart::UnstableNode divValue(VM vm, nativeint b);

  inline
  class mozart::UnstableNode mod(VM vm, class mozart::RichNode right);

  inline
  class mozart::UnstableNode modValue(VM vm, nativeint b);

  inline
  class mozart::UnstableNode abs(VM vm);

  inline
  void printReprToStream(VM vm, std::ostream & out, int depth, int width);
};
