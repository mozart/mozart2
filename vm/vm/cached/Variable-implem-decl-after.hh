template <>
class TypeInfoOf<Variable>: public TypeInfo {

  static constexpr UUID uuid() {
    return UUID();
  }
public:
  TypeInfoOf() : TypeInfo("Variable", uuid(), false, true, false, sbVariable, 90) {}

  static const TypeInfoOf<Variable>* const instance() {
    return &RawType<Variable>::rawType;
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
class TypedRichNode<Variable>: public BaseTypedRichNode {
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
  void wakeUp(VM vm);

  inline
  bool shouldWakeUpUnderSpace(VM vm, class mozart::Space * space);

  inline
  void bind(VM vm, class mozart::RichNode src);

  inline
  void printReprToStream(VM vm, std::ostream & out, int depth, int width);
};
