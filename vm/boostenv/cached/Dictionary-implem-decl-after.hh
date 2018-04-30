template <>
class TypeInfoOf<Dictionary>: public TypeInfo {

  static constexpr UUID uuid() {
    return UUID();
  }
public:
  TypeInfoOf() : TypeInfo("Dictionary", uuid(), false, false, false, sbTokenEq, 0) {}

  static const TypeInfoOf<Dictionary>* const instance() {
    return &RawType<Dictionary>::rawType;
  }

  static Type type() {
    return Type(instance());
  }

  atom_t getTypeAtom(VM vm) const {
    return Dictionary::getTypeAtom(vm);
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
};

template <>
class TypedRichNode<Dictionary>: public BaseTypedRichNode {
public:
  explicit TypedRichNode(RichNode self) : BaseTypedRichNode(self) {}

  inline
  class mozart::Space * home();

  inline
  bool lookupFeature(VM vm, class mozart::RichNode feature, nullable<class mozart::UnstableNode &> value);

  inline
  bool lookupFeature(VM vm, nativeint feature, nullable<class mozart::UnstableNode &> value);

  inline
  void dotAssign(VM vm, class mozart::RichNode feature, class mozart::RichNode newValue);

  inline
  class mozart::UnstableNode dotExchange(VM vm, class mozart::RichNode feature, class mozart::RichNode newValue);

  inline
  bool isDictionary(VM vm);

  inline
  bool dictIsEmpty(VM vm);

  inline
  bool dictMember(VM vm, class mozart::RichNode feature);

  inline
  class mozart::UnstableNode dictGet(VM vm, class mozart::RichNode feature);

  inline
  class mozart::UnstableNode dictCondGet(VM vm, class mozart::RichNode feature, class mozart::RichNode defaultValue);

  inline
  void dictPut(VM vm, class mozart::RichNode feature, class mozart::RichNode newValue);

  inline
  class mozart::UnstableNode dictExchange(VM vm, class mozart::RichNode feature, class mozart::RichNode newValue);

  inline
  class mozart::UnstableNode dictCondExchange(VM vm, class mozart::RichNode feature, class mozart::RichNode defaultValue, class mozart::RichNode newValue);

  inline
  void dictRemove(VM vm, class mozart::RichNode feature);

  inline
  void dictRemoveAll(VM vm);

  inline
  class mozart::UnstableNode dictKeys(VM vm);

  inline
  class mozart::UnstableNode dictEntries(VM vm);

  inline
  class mozart::UnstableNode dictItems(VM vm);

  inline
  class mozart::UnstableNode dictClone(VM vm);

  inline
  void printReprToStream(VM vm, std::ostream & out, int depth, int width);

  inline
  class mozart::NodeDictionary & getDict();
};
