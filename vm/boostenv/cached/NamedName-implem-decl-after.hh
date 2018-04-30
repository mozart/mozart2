template <>
class TypeInfoOf<NamedName>: public TypeInfo {

  static constexpr UUID uuid() {
    return NamedName::uuid;
  }
public:
  TypeInfoOf() : TypeInfo("NamedName", uuid(), false, false, true, sbTokenEq, 0) {}

  static const TypeInfoOf<NamedName>* const instance() {
    return &RawType<NamedName>::rawType;
  }

  static Type type() {
    return Type(instance());
  }

  atom_t getTypeAtom(VM vm) const {
    return NamedName::getTypeAtom(vm);
  }

  inline
  void printReprToStream(VM vm, RichNode self, std::ostream& out,
                         int depth, int width) const;

  inline
  UnstableNode serialize(VM vm, SE s, RichNode from) const;

  inline
  GlobalNode* globalize(VM vm, RichNode from) const;

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
class TypedRichNode<NamedName>: public BaseTypedRichNode {
public:
  explicit TypedRichNode(RichNode self) : BaseTypedRichNode(self) {}

  inline
  class mozart::Space * home();

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
  const struct mozart::UUID & getUUID();

  inline
  int compareFeatures(VM vm, class mozart::RichNode right);

  inline
  atom_t getPrintName(VM vm);

  inline
  bool isName(VM vm);

  inline
  class mozart::UnstableNode serialize(VM vm, SE se);

  inline
  class mozart::GlobalNode * globalize(VM vm);

  inline
  void printReprToStream(VM vm, std::ostream & out, int depth, int width);
};
