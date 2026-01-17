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
  mozart::Space * home();

  inline
  bool isLiteral(mozart::VM vm);

  inline
  bool lookupFeature(mozart::VM vm, mozart::RichNode feature, nullable<mozart::UnstableNode &> value);

  inline
  bool lookupFeature(mozart::VM vm, mozart::nativeint feature, nullable<mozart::UnstableNode &> value);

  inline
  bool isRecord(mozart::VM vm);

  inline
  bool isTuple(mozart::VM vm);

  inline
  mozart::UnstableNode label(mozart::VM vm);

  inline
  size_t width(mozart::VM vm);

  inline
  mozart::UnstableNode arityList(mozart::VM vm);

  inline
  mozart::UnstableNode clone(mozart::VM vm);

  inline
  mozart::UnstableNode waitOr(mozart::VM vm);

  inline
  bool testRecord(mozart::VM vm, mozart::RichNode arity);

  inline
  bool testTuple(mozart::VM vm, mozart::RichNode label, size_t width);

  inline
  bool testLabel(mozart::VM vm, mozart::RichNode label);

  inline
  const mozart::UUID & getUUID();

  inline
  int compareFeatures(mozart::VM vm, mozart::RichNode right);

  inline
  mozart::atom_t getPrintName(mozart::VM vm);

  inline
  bool isName(mozart::VM vm);

  inline
  mozart::UnstableNode serialize(mozart::VM vm, mozart::SE se);

  inline
  mozart::GlobalNode * globalize(mozart::VM vm);

  inline
  void printReprToStream(mozart::VM vm, std::ostream & out, int depth, int width);
};
