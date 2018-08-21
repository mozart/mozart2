template <>
class TypeInfoOf<VMPort>: public TypeInfo {

  static constexpr UUID uuid() {
    return UUID();
  }
public:
  TypeInfoOf() : TypeInfo("VMPort", uuid(), (! ::mozart::MemWord::requiresExternalMemory<VMIdentifier>()), false, false, sbValue, 0) {}

  static const TypeInfoOf<VMPort>* const instance() {
    return &RawType<VMPort>::rawType;
  }

  static Type type() {
    return Type(instance());
  }

  atom_t getTypeAtom(VM vm) const {
    return VMPort::getTypeAtom(vm);
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
class TypedRichNode<VMPort>: public BaseTypedRichNode {
public:
  explicit TypedRichNode(RichNode self) : BaseTypedRichNode(self) {}

  inline
  VMIdentifier value();

  inline
  bool equals(VM vm, class mozart::RichNode right);

  inline
  bool isPort(VM vm);

  inline
  void send(VM vm, class mozart::RichNode value);

  inline
  class mozart::UnstableNode sendReceive(VM vm, class mozart::RichNode value);

  inline
  void printReprToStream(VM vm, std::ostream & out, int depth, int width);
};
