template <>
class TypeInfoOf<FailedValue>: public TypeInfo {

  static constexpr UUID uuid() {
    return UUID();
  }
public:
  TypeInfoOf() : TypeInfo("FailedValue", uuid(), false, true, false, sbVariable, 10) {}

  static const TypeInfoOf<FailedValue>* const instance() {
    return &RawType<FailedValue>::rawType;
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
class TypedRichNode<FailedValue>: public BaseTypedRichNode {
public:
  explicit TypedRichNode(RichNode self) : BaseTypedRichNode(self) {}

  inline
  mozart::StableNode * getUnderlying();

  inline
  void raiseUnderlying(mozart::VM vm);

  inline
  void addToSuspendList(mozart::VM vm, mozart::RichNode variable);

  inline
  bool isNeeded(mozart::VM vm);

  inline
  void markNeeded(mozart::VM vm);

  inline
  void bind(mozart::VM vm, mozart::RichNode src);

  inline
  void printReprToStream(mozart::VM vm, std::ostream & out, int depth, int width);
};
