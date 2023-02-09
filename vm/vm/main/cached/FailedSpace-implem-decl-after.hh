template <>
class TypeInfoOf<FailedSpace>: public TypeInfo {

  static constexpr UUID uuid() {
    return UUID();
  }
public:
  TypeInfoOf() : TypeInfo("FailedSpace", uuid(), false, false, false, sbTokenEq, 0) {}

  static const TypeInfoOf<FailedSpace>* const instance() {
    return &RawType<FailedSpace>::rawType;
  }

  static Type type() {
    return Type(instance());
  }

  atom_t getTypeAtom(VM vm) const {
    return FailedSpace::getTypeAtom(vm);
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
class TypedRichNode<FailedSpace>: public BaseTypedRichNode {
public:
  explicit TypedRichNode(RichNode self) : BaseTypedRichNode(self) {}

  inline
  bool isSpace(mozart::VM vm);

  inline
  mozart::UnstableNode askSpace(mozart::VM vm);

  inline
  mozart::UnstableNode askVerboseSpace(mozart::VM vm);

  inline
  mozart::UnstableNode mergeSpace(mozart::VM vm);

  inline
  void commitSpace(mozart::VM vm, mozart::RichNode value);

  inline
  mozart::UnstableNode cloneSpace(mozart::VM vm);

  inline
  void killSpace(mozart::VM vm);
};
