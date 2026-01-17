template <>
class TypeInfoOf<Reference>: public TypeInfo {

  static constexpr UUID uuid() {
    return UUID();
  }
public:
  TypeInfoOf() : TypeInfo("Reference", uuid(), (! ::mozart::MemWord::requiresExternalMemory<mozart::StableNode *>()), false, false, sbValue, 0) {}

  static const TypeInfoOf<Reference>* const instance() {
    return &RawType<Reference>::rawType;
  }

  static Type type() {
    return Type(instance());
  }

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
class TypedRichNode<Reference>: public BaseTypedRichNode {
public:
  explicit TypedRichNode(RichNode self) : BaseTypedRichNode(self) {}

  inline
  mozart::StableNode * dest();
};
