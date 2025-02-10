template <>
class TypeInfoOf<String>: public TypeInfo {

  static constexpr UUID uuid() {
    return String::uuid;
  }
public:
  TypeInfoOf() : TypeInfo("String", uuid(), false, false, false, sbValue, 0) {}

  static const TypeInfoOf<String>* const instance() {
    return &RawType<String>::rawType;
  }

  static Type type() {
    return Type(instance());
  }

  atom_t getTypeAtom(VM vm) const {
    return String::getTypeAtom(vm);
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
class TypedRichNode<String>: public BaseTypedRichNode {
public:
  explicit TypedRichNode(RichNode self) : BaseTypedRichNode(self) {}

  inline
  const LString<char> & value();

  inline
  bool equals(mozart::VM vm, mozart::RichNode right);

  inline
  int compare(mozart::VM vm, mozart::RichNode right);

  inline
  bool isString(mozart::VM vm);

  inline
  bool isByteString(mozart::VM vm);

  inline
  LString<char> * stringGet(mozart::VM vm);

  inline
  LString<unsigned char> * byteStringGet(mozart::VM vm);

  inline
  mozart::nativeint stringCharAt(mozart::VM vm, mozart::RichNode offset);

  inline
  mozart::UnstableNode stringAppend(mozart::VM vm, mozart::RichNode right);

  inline
  mozart::UnstableNode stringSlice(mozart::VM vm, mozart::RichNode from, mozart::RichNode to);

  inline
  void stringSearch(mozart::VM vm, mozart::RichNode from, mozart::RichNode needle, mozart::UnstableNode & begin, mozart::UnstableNode & end);

  inline
  bool stringHasPrefix(mozart::VM vm, mozart::RichNode prefix);

  inline
  bool stringHasSuffix(mozart::VM vm, mozart::RichNode suffix);

  inline
  bool lookupFeature(mozart::VM vm, mozart::RichNode feature, nullable<mozart::UnstableNode &> value);

  inline
  bool lookupFeature(mozart::VM vm, mozart::nativeint feature, nullable<mozart::UnstableNode &> value);

  inline
  void printReprToStream(mozart::VM vm, std::ostream & out, int depth, int width);
};
