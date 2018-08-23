template <>
class TypeInfoOf<ReflectiveVariable>: public TypeInfo {

  static constexpr UUID uuid() {
    return UUID();
  }
public:
  TypeInfoOf() : TypeInfo("ReflectiveVariable", uuid(), false, true, false, sbVariable, 85) {}

  static const TypeInfoOf<ReflectiveVariable>* const instance() {
    return &RawType<ReflectiveVariable>::rawType;
  }

  static Type type() {
    return Type(instance());
  }

  inline
  void printReprToStream(VM vm, RichNode self, std::ostream& out,
                         int depth, int width) const;

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
class TypedRichNode<ReflectiveVariable>: public BaseTypedRichNode {
public:
  explicit TypedRichNode(RichNode self) : BaseTypedRichNode(self) {}

  inline
  class mozart::Space * home();

  inline
  void addToSuspendList(VM vm, class mozart::RichNode variable);

  inline
  bool isNeeded(VM vm);

  inline
  void markNeeded(VM vm);

  inline
  void bind(VM vm, class mozart::RichNode src);

  inline
  void reflectiveBind(VM vm, class mozart::RichNode src);

  inline
  void bindReadOnly(VM vm, class mozart::RichNode src);

  inline
  void printReprToStream(VM vm, std::ostream & out, int depth, int width);
};
