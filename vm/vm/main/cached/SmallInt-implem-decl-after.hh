template <>
class TypeInfoOf<SmallInt>: public TypeInfo {

  static constexpr UUID uuid() {
    return SmallInt::uuid;
  }
public:
  TypeInfoOf() : TypeInfo("SmallInt", uuid(), (! ::mozart::MemWord::requiresExternalMemory<mozart::nativeint>()), false, true, sbValue, 0) {}

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
  mozart::nativeint value();

  inline
  bool equals(mozart::VM vm, mozart::RichNode right);

  inline
  int compareFeatures(mozart::VM vm, mozart::RichNode right);

  inline
  int compare(mozart::VM vm, mozart::RichNode right);

  inline
  bool isNumber(mozart::VM vm);

  inline
  bool isInt(mozart::VM vm);

  inline
  bool isFloat(mozart::VM vm);

  inline
  mozart::UnstableNode opposite(mozart::VM vm);

  inline
  mozart::UnstableNode add(mozart::VM vm, mozart::RichNode right);

  inline
  mozart::UnstableNode add(mozart::VM vm, mozart::nativeint b);

  inline
  mozart::UnstableNode subtract(mozart::VM vm, mozart::RichNode right);

  inline
  mozart::UnstableNode subtractValue(mozart::VM vm, mozart::nativeint b);

  inline
  mozart::UnstableNode multiply(mozart::VM vm, mozart::RichNode right);

  inline
  mozart::UnstableNode multiplyValue(mozart::VM vm, mozart::nativeint b);

  inline
  mozart::UnstableNode div(mozart::VM vm, mozart::RichNode right);

  inline
  mozart::UnstableNode divValue(mozart::VM vm, mozart::nativeint b);

  inline
  mozart::UnstableNode mod(mozart::VM vm, mozart::RichNode right);

  inline
  mozart::UnstableNode modValue(mozart::VM vm, mozart::nativeint b);

  inline
  mozart::UnstableNode abs(mozart::VM vm);

  inline
  void printReprToStream(mozart::VM vm, std::ostream & out, int depth, int width);
};
