template <>
class TypeInfoOf<Float>: public TypeInfo {

  static constexpr UUID uuid() {
    return UUID();
  }
public:
  TypeInfoOf() : TypeInfo("Float", uuid(), (! ::mozart::MemWord::requiresExternalMemory<double>()), false, false, sbValue, 0) {}

  static const TypeInfoOf<Float>* const instance() {
    return &RawType<Float>::rawType;
  }

  static Type type() {
    return Type(instance());
  }

  atom_t getTypeAtom(VM vm) const {
    return Float::getTypeAtom(vm);
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
class TypedRichNode<Float>: public BaseTypedRichNode {
public:
  explicit TypedRichNode(RichNode self) : BaseTypedRichNode(self) {}

  inline
  double value();

  inline
  bool equals(VM vm, class mozart::RichNode right);

  inline
  int compare(VM vm, class mozart::RichNode right);

  inline
  bool isNumber(VM vm);

  inline
  bool isInt(VM vm);

  inline
  bool isFloat(VM vm);

  inline
  class mozart::UnstableNode opposite(VM vm);

  inline
  class mozart::UnstableNode add(VM vm, class mozart::RichNode right);

  inline
  class mozart::UnstableNode add(VM vm, nativeint right);

  inline
  class mozart::UnstableNode addValue(VM vm, double b);

  inline
  class mozart::UnstableNode subtract(VM vm, class mozart::RichNode right);

  inline
  class mozart::UnstableNode subtractValue(VM vm, double b);

  inline
  class mozart::UnstableNode multiply(VM vm, class mozart::RichNode right);

  inline
  class mozart::UnstableNode multiplyValue(VM vm, double b);

  inline
  class mozart::UnstableNode divide(VM vm, class mozart::RichNode right);

  inline
  class mozart::UnstableNode divideValue(VM vm, double b);

  inline
  class mozart::UnstableNode fmod(VM vm, class mozart::RichNode right);

  inline
  class mozart::UnstableNode fmodValue(VM vm, double b);

  inline
  class mozart::UnstableNode div(VM vm, class mozart::RichNode right);

  inline
  class mozart::UnstableNode mod(VM vm, class mozart::RichNode right);

  inline
  class mozart::UnstableNode pow(VM vm, class mozart::RichNode right);

  inline
  class mozart::UnstableNode powValue(VM vm, double b);

  inline
  class mozart::UnstableNode abs(VM vm);

  inline
  class mozart::UnstableNode acos(VM vm);

  inline
  class mozart::UnstableNode acosh(VM vm);

  inline
  class mozart::UnstableNode asin(VM vm);

  inline
  class mozart::UnstableNode asinh(VM vm);

  inline
  class mozart::UnstableNode atan(VM vm);

  inline
  class mozart::UnstableNode atanh(VM vm);

  inline
  class mozart::UnstableNode atan2(VM vm, class mozart::RichNode right);

  inline
  class mozart::UnstableNode atan2Value(VM vm, double b);

  inline
  class mozart::UnstableNode ceil(VM vm);

  inline
  class mozart::UnstableNode cos(VM vm);

  inline
  class mozart::UnstableNode cosh(VM vm);

  inline
  class mozart::UnstableNode exp(VM vm);

  inline
  class mozart::UnstableNode floor(VM vm);

  inline
  class mozart::UnstableNode log(VM vm);

  inline
  class mozart::UnstableNode round(VM vm);

  inline
  class mozart::UnstableNode sin(VM vm);

  inline
  class mozart::UnstableNode sinh(VM vm);

  inline
  class mozart::UnstableNode sqrt(VM vm);

  inline
  class mozart::UnstableNode tan(VM vm);

  inline
  class mozart::UnstableNode tanh(VM vm);

  inline
  void printReprToStream(VM vm, std::ostream & out, int depth, int width);
};
