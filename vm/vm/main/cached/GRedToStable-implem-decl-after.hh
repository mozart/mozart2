template <>
class TypeInfoOf<GRedToStable>: public GRedToStableBase {

  static constexpr UUID uuid() {
    return UUID();
  }
public:
  TypeInfoOf() : GRedToStableBase("GRedToStable", uuid(), false, false, false, sbTokenEq, 0) {}

  static const TypeInfoOf<GRedToStable>* const instance() {
    return &RawType<GRedToStable>::rawType;
  }

  static Type type() {
    return Type(instance());
  }
};

template <>
class TypedRichNode<GRedToStable>: public BaseTypedRichNode {
public:
  explicit TypedRichNode(RichNode self) : BaseTypedRichNode(self) {}

  inline
  mozart::StableNode * dest();
};
