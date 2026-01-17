template <>
class TypeInfoOf<Cell>: public TypeInfo {

  static constexpr UUID uuid() {
    return UUID();
  }
public:
  TypeInfoOf() : TypeInfo("Cell", uuid(), false, false, false, sbTokenEq, 0) {}

  static const TypeInfoOf<Cell>* const instance() {
    return &RawType<Cell>::rawType;
  }

  static Type type() {
    return Type(instance());
  }

  atom_t getTypeAtom(VM vm) const {
    return Cell::getTypeAtom(vm);
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
class TypedRichNode<Cell>: public BaseTypedRichNode {
public:
  explicit TypedRichNode(RichNode self) : BaseTypedRichNode(self) {}

  inline
  mozart::Space * home();

  inline
  bool isCell(mozart::VM vm);

  inline
  mozart::UnstableNode exchange(mozart::VM vm, mozart::RichNode newValue);

  inline
  mozart::UnstableNode access(mozart::VM vm);

  inline
  void assign(mozart::VM vm, mozart::RichNode newValue);

  inline
  void printReprToStream(mozart::VM vm, std::ostream & out, int depth, int width);
};
