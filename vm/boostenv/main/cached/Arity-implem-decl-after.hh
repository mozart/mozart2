template <>
class TypeInfoOf<Arity>: public TypeInfo {

  static constexpr UUID uuid() {
    return UUID();
  }
public:
  TypeInfoOf() : TypeInfo("Arity", uuid(), false, false, false, sbStructural, 0) {}

  static const TypeInfoOf<Arity>* const instance() {
    return &RawType<Arity>::rawType;
  }

  static Type type() {
    return Type(instance());
  }

  atom_t getTypeAtom(VM vm) const {
    return Arity::getTypeAtom(vm);
  }

  inline
  void printReprToStream(VM vm, RichNode self, std::ostream& out,
                         int depth, int width) const;

  inline
  UnstableNode serialize(VM vm, SE s, RichNode from) const;

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
class TypedRichNode<Arity>: public BaseTypedRichNode {
public:
  explicit TypedRichNode(RichNode self) : BaseTypedRichNode(self) {}

  inline
  size_t getArraySize();

  inline
  StaticArray<mozart::StableNode> getElementsArray();

  inline
  mozart::StableNode& getElements(size_t i);

  inline
  size_t getArraySizeImpl();

  inline
  mozart::StableNode * getLabel();

  inline
  size_t getWidth();

  inline
  mozart::StableNode * getElement(size_t index);

  inline
  bool equals(mozart::VM vm, mozart::RichNode right, mozart::WalkStack & stack);

  inline
  bool lookupFeature(mozart::VM vm, mozart::RichNode feature, size_t & offset);

  inline
  void printReprToStream(mozart::VM vm, std::ostream & out, int depth, int width);

  inline
  mozart::UnstableNode serialize(mozart::VM vm, mozart::SE se);
};
