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
  mozart::Space * home();

  inline
  bool lookupFeature(mozart::VM vm, mozart::RichNode feature, nullable<mozart::UnstableNode &> value);

  inline
  bool lookupFeature(mozart::VM vm, mozart::nativeint feature, nullable<mozart::UnstableNode &> value);

  inline
  void dotAssign(mozart::VM vm, mozart::RichNode feature, mozart::RichNode newValue);

  inline
  mozart::UnstableNode dotExchange(mozart::VM vm, mozart::RichNode feature, mozart::RichNode newValue);

  inline
  bool isDictionary(mozart::VM vm);

  inline
  bool dictIsEmpty(mozart::VM vm);

  inline
  bool dictMember(mozart::VM vm, mozart::RichNode feature);

  inline
  mozart::UnstableNode dictGet(mozart::VM vm, mozart::RichNode feature);

  inline
  mozart::UnstableNode dictCondGet(mozart::VM vm, mozart::RichNode feature, mozart::RichNode defaultValue);

  inline
  void dictPut(mozart::VM vm, mozart::RichNode feature, mozart::RichNode newValue);

  inline
  mozart::UnstableNode dictExchange(mozart::VM vm, mozart::RichNode feature, mozart::RichNode newValue);

  inline
  mozart::UnstableNode dictCondExchange(mozart::VM vm, mozart::RichNode feature, mozart::RichNode defaultValue, mozart::RichNode newValue);

  inline
  void dictRemove(mozart::VM vm, mozart::RichNode feature);

  inline
  void dictRemoveAll(mozart::VM vm);

  inline
  mozart::UnstableNode dictKeys(mozart::VM vm);

  inline
  mozart::UnstableNode dictEntries(mozart::VM vm);

  inline
  mozart::UnstableNode dictItems(mozart::VM vm);

  inline
  mozart::UnstableNode dictClone(mozart::VM vm);

  inline
  void printReprToStream(mozart::VM vm, std::ostream & out, int depth, int width);

  inline
  mozart::NodeDictionary & getDict();
};
