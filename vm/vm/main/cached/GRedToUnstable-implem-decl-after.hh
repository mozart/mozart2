template <>
class TypeInfoOf<GRedToUnstable>: public GRedToUnstableBase {

  static constexpr UUID uuid() {
    return UUID();
  }
public:
  TypeInfoOf() : GRedToUnstableBase("GRedToUnstable", uuid(), false, false, false, sbTokenEq, 0) {}

  static const TypeInfoOf<GRedToUnstable>* const instance() {
    return &RawType<GRedToUnstable>::rawType;
  }

  static Type type() {
    return Type(instance());
  }
};

template <>
class TypedRichNode<GRedToUnstable>: public BaseTypedRichNode {
public:
  explicit TypedRichNode(RichNode self) : BaseTypedRichNode(self) {}

  inline
  mozart::UnstableNode * dest();
};
