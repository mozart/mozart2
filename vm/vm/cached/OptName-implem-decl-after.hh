template <>
class TypeInfoOf<OptName>: public TypeInfo {

  static constexpr UUID uuid() {
    return UUID();
  }
public:
  TypeInfoOf() : TypeInfo("OptName", uuid(), false, false, false, sbTokenEq, 0) {}

  static const TypeInfoOf<OptName>* const instance() {
    return &RawType<OptName>::rawType;
  }

  static Type type() {
    return Type(instance());
  }

  atom_t getTypeAtom(VM vm) const {
    return OptName::getTypeAtom(vm);
  }

  inline
  void printReprToStream(VM vm, RichNode self, std::ostream& out,
                         int depth, int width) const;

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
};

template <>
class TypedRichNode<OptName>: public BaseTypedRichNode {
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
  void makeFeature(VM vm);

  inline
  bool isName(VM vm);

  inline
  class mozart::GlobalNode * globalize(VM vm);

  inline
  void printReprToStream(VM vm, std::ostream & out, int depth, int width);
};
