template <>
class TypeInfoOf<Serialized>: public TypeInfo {

  static constexpr UUID uuid() {
    return UUID();
  }
public:
  TypeInfoOf() : TypeInfo("Serialized", uuid(), false, false, false, sbTokenEq, 0) {}

  static const TypeInfoOf<Serialized>* const instance() {
    return &RawType<Serialized>::rawType;
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
class TypedRichNode<Serialized>: public BaseTypedRichNode {
public:
  explicit TypedRichNode(RichNode self) : BaseTypedRichNode(self) {}

  inline
  mozart::nativeint n();
};
