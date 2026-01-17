template <>
class TypeInfoOf<PatMatCapture>: public TypeInfo {

  static constexpr UUID uuid() {
    return UUID();
  }
public:
  TypeInfoOf() : TypeInfo("PatMatCapture", uuid(), (! ::mozart::MemWord::requiresExternalMemory<mozart::nativeint>()), false, false, sbValue, 0) {}

  static const TypeInfoOf<PatMatCapture>* const instance() {
    return &RawType<PatMatCapture>::rawType;
  }

  static Type type() {
    return Type(instance());
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
};

template <>
class TypedRichNode<PatMatCapture>: public BaseTypedRichNode {
public:
  explicit TypedRichNode(RichNode self) : BaseTypedRichNode(self) {}

  inline
  mozart::nativeint index();

  inline
  bool equals(mozart::VM vm, mozart::RichNode right);

  inline
  void printReprToStream(mozart::VM vm, std::ostream & out, int depth, int width);

  inline
  mozart::UnstableNode serialize(mozart::VM vm, mozart::SE se);
};
