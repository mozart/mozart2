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
  mozart::Space * home();

  inline
  void addToSuspendList(mozart::VM vm, mozart::RichNode variable);

  inline
  bool isNeeded(mozart::VM vm);

  inline
  void markNeeded(mozart::VM vm);

  inline
  void bind(mozart::VM vm, mozart::RichNode src);

  inline
  void reflectiveBind(mozart::VM vm, mozart::RichNode src);

  inline
  void bindReadOnly(mozart::VM vm, mozart::RichNode src);

  inline
  void printReprToStream(mozart::VM vm, std::ostream & out, int depth, int width);
};
