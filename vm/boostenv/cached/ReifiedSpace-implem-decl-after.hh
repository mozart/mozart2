template <>
class TypeInfoOf<ReifiedSpace>: public TypeInfo {

  static constexpr UUID uuid() {
    return UUID();
  }
public:
  TypeInfoOf() : TypeInfo("ReifiedSpace", uuid(), false, false, false, sbTokenEq, 0) {}

  static const TypeInfoOf<ReifiedSpace>* const instance() {
    return &RawType<ReifiedSpace>::rawType;
  }

  static Type type() {
    return Type(instance());
  }

  atom_t getTypeAtom(VM vm) const {
    return ReifiedSpace::getTypeAtom(vm);
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
class TypedRichNode<ReifiedSpace>: public BaseTypedRichNode {
public:
  explicit TypedRichNode(RichNode self) : BaseTypedRichNode(self) {}

  inline
  class mozart::Space * home();

  inline
  class mozart::Space * getSpace();

  inline
  bool isSpace(VM vm);

  inline
  class mozart::UnstableNode askSpace(VM vm);

  inline
  class mozart::UnstableNode askVerboseSpace(VM vm);

  inline
  class mozart::UnstableNode mergeSpace(VM vm);

  inline
  void commitSpace(VM vm, class mozart::RichNode value);

  inline
  class mozart::UnstableNode cloneSpace(VM vm);

  inline
  void killSpace(VM vm);
};
