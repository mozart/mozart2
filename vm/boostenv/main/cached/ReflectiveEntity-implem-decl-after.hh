template <>
class TypeInfoOf<ReflectiveEntity>: public TypeInfo {

  static constexpr UUID uuid() {
    return UUID();
  }
public:
  TypeInfoOf() : TypeInfo("ReflectiveEntity", uuid(), false, false, false, sbTokenEq, 0) {}

  static const TypeInfoOf<ReflectiveEntity>* const instance() {
    return &RawType<ReflectiveEntity>::rawType;
  }

  static Type type() {
    return Type(instance());
  }

  atom_t getTypeAtom(VM vm) const {
    return ReflectiveEntity::getTypeAtom(vm);
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
class TypedRichNode<ReflectiveEntity>: public BaseTypedRichNode {
public:
  explicit TypedRichNode(RichNode self) : BaseTypedRichNode(self) {}

  template <typename Label, typename ... Args> 
  inline
  bool reflectiveCall(mozart::VM vm, const char * identity, Label && label, Args &&... args);

  inline
  void printReprToStream(mozart::VM vm, std::ostream & out, int depth, int width);
};
