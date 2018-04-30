template <>
class TypeInfoOf<ForeignPointer>: public TypeInfo {

  static constexpr UUID uuid() {
    return UUID();
  }
public:
  TypeInfoOf() : TypeInfo("ForeignPointer", uuid(), false, false, false, sbTokenEq, 0) {}

  static const TypeInfoOf<ForeignPointer>* const instance() {
    return &RawType<ForeignPointer>::rawType;
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
class TypedRichNode<ForeignPointer>: public BaseTypedRichNode {
public:
  explicit TypedRichNode(RichNode self) : BaseTypedRichNode(self) {}

  template <class T> 
  inline
  std::shared_ptr<T> value();

  inline
  std::shared_ptr<void> getVoidPointer();

  inline
  const std::type_info & pointerType();

  template <class T> 
  inline
  bool isPointer();
};
