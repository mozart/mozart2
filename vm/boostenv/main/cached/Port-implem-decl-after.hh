template <>
class TypeInfoOf<Port>: public TypeInfo {

  static constexpr UUID uuid() {
    return UUID();
  }
public:
  TypeInfoOf() : TypeInfo("Port", uuid(), false, false, false, sbTokenEq, 0) {}

  static const TypeInfoOf<Port>* const instance() {
    return &RawType<Port>::rawType;
  }

  static Type type() {
    return Type(instance());
  }

  atom_t getTypeAtom(VM vm) const {
    return Port::getTypeAtom(vm);
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
class TypedRichNode<Port>: public BaseTypedRichNode {
public:
  explicit TypedRichNode(RichNode self) : BaseTypedRichNode(self) {}

  inline
  mozart::Space * home();

  inline
  bool isPort(mozart::VM vm);

  inline
  void send(mozart::VM vm, mozart::RichNode value);

  inline
  mozart::UnstableNode sendReceive(mozart::VM vm, mozart::RichNode value);

  inline
  void printReprToStream(mozart::VM vm, std::ostream & out, int depth, int width);
};
