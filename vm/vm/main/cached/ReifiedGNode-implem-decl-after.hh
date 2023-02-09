template <>
class TypeInfoOf<ReifiedGNode>: public TypeInfo {

  static constexpr UUID uuid() {
    return UUID();
  }
public:
  TypeInfoOf() : TypeInfo("ReifiedGNode", uuid(), (! ::mozart::MemWord::requiresExternalMemory<mozart::GlobalNode *>()), false, false, sbValue, 0) {}

  static const TypeInfoOf<ReifiedGNode>* const instance() {
    return &RawType<ReifiedGNode>::rawType;
  }

  static Type type() {
    return Type(instance());
  }

  atom_t getTypeAtom(VM vm) const {
    return ReifiedGNode::getTypeAtom(vm);
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
class TypedRichNode<ReifiedGNode>: public BaseTypedRichNode {
public:
  explicit TypedRichNode(RichNode self) : BaseTypedRichNode(self) {}

  inline
  mozart::GlobalNode * value();

  inline
  bool equals(mozart::VM vm, mozart::RichNode right);
};
