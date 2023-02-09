template <>
class TypeInfoOf<WeakReference>: public TypeInfo {

  static constexpr UUID uuid() {
    return UUID();
  }
public:
  TypeInfoOf() : TypeInfo("WeakReference", uuid(), false, false, false, sbTokenEq, 0) {}

  static const TypeInfoOf<WeakReference>* const instance() {
    return &RawType<WeakReference>::rawType;
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
class TypedRichNode<WeakReference>: public BaseTypedRichNode {
public:
  explicit TypedRichNode(RichNode self) : BaseTypedRichNode(self) {}

  inline
  mozart::StableNode * getUnderlying();
};
