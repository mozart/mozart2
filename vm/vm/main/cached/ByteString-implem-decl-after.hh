template <>
class TypeInfoOf<ByteString>: public TypeInfo {

  static constexpr UUID uuid() {
    return ByteString::uuid;
  }
public:
  TypeInfoOf() : TypeInfo("ByteString", uuid(), false, false, false, sbValue, 0) {}

  static const TypeInfoOf<ByteString>* const instance() {
    return &RawType<ByteString>::rawType;
  }

  static Type type() {
    return Type(instance());
  }

  atom_t getTypeAtom(VM vm) const {
    return ByteString::getTypeAtom(vm);
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
class TypedRichNode<ByteString>: public BaseTypedRichNode {
public:
  explicit TypedRichNode(RichNode self) : BaseTypedRichNode(self) {}

  inline
  bool lookupFeature(VM vm, class mozart::RichNode feature, nullable<class mozart::UnstableNode &> value);

  inline
  bool lookupFeature(VM vm, nativeint feature, nullable<class mozart::UnstableNode &> value);

  inline
  const LString<unsigned char> & value();

  inline
  bool equals(VM vm, class mozart::RichNode right);

  inline
  int compare(VM vm, class mozart::RichNode right);

  inline
  bool isString(VM vm);

  inline
  bool isByteString(VM vm);

  inline
  LString<char> * stringGet(VM vm);

  inline
  LString<unsigned char> * byteStringGet(VM vm);

  inline
  nativeint stringCharAt(VM vm, class mozart::RichNode offset);

  inline
  class mozart::UnstableNode stringAppend(VM vm, class mozart::RichNode right);

  inline
  class mozart::UnstableNode stringSlice(VM vm, class mozart::RichNode from, class mozart::RichNode to);

  inline
  void stringSearch(VM vm, class mozart::RichNode from, class mozart::RichNode needle, class mozart::UnstableNode & begin, class mozart::UnstableNode & end);

  inline
  bool stringHasPrefix(VM vm, class mozart::RichNode prefix);

  inline
  bool stringHasSuffix(VM vm, class mozart::RichNode suffix);

  inline
  void printReprToStream(VM vm, std::ostream & out, int depth, int width);
};
