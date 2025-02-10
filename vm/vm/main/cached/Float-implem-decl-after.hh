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
  bool equals(mozart::VM vm, mozart::RichNode right);

  inline
  int compare(mozart::VM vm, mozart::RichNode right);

  inline
  bool isNumber(mozart::VM vm);

  inline
  bool isInt(mozart::VM vm);

  inline
  bool isFloat(mozart::VM vm);

  inline
  mozart::UnstableNode opposite(mozart::VM vm);

  inline
  mozart::UnstableNode add(mozart::VM vm, mozart::RichNode right);

  inline
  mozart::UnstableNode add(mozart::VM vm, mozart::nativeint right);

  inline
  mozart::UnstableNode addValue(mozart::VM vm, double b);

  inline
  mozart::UnstableNode subtract(mozart::VM vm, mozart::RichNode right);

  inline
  mozart::UnstableNode subtractValue(mozart::VM vm, double b);

  inline
  mozart::UnstableNode multiply(mozart::VM vm, mozart::RichNode right);

  inline
  mozart::UnstableNode multiplyValue(mozart::VM vm, double b);

  inline
  mozart::UnstableNode divide(mozart::VM vm, mozart::RichNode right);

  inline
  mozart::UnstableNode divideValue(mozart::VM vm, double b);

  inline
  mozart::UnstableNode fmod(mozart::VM vm, mozart::RichNode right);

  inline
  mozart::UnstableNode fmodValue(mozart::VM vm, double b);

  inline
  mozart::UnstableNode div(mozart::VM vm, mozart::RichNode right);

  inline
  mozart::UnstableNode mod(mozart::VM vm, mozart::RichNode right);

  inline
  mozart::UnstableNode pow(mozart::VM vm, mozart::RichNode right);

  inline
  mozart::UnstableNode powValue(mozart::VM vm, double b);

  inline
  mozart::UnstableNode abs(mozart::VM vm);

  inline
  mozart::UnstableNode acos(mozart::VM vm);

  inline
  mozart::UnstableNode acosh(mozart::VM vm);

  inline
  mozart::UnstableNode asin(mozart::VM vm);

  inline
  mozart::UnstableNode asinh(mozart::VM vm);

  inline
  mozart::UnstableNode atan(mozart::VM vm);

  inline
  mozart::UnstableNode atanh(mozart::VM vm);

  inline
  mozart::UnstableNode atan2(mozart::VM vm, mozart::RichNode right);

  inline
  mozart::UnstableNode atan2Value(mozart::VM vm, double b);

  inline
  mozart::UnstableNode ceil(mozart::VM vm);

  inline
  mozart::UnstableNode cos(mozart::VM vm);

  inline
  mozart::UnstableNode cosh(mozart::VM vm);

  inline
  mozart::UnstableNode exp(mozart::VM vm);

  inline
  mozart::UnstableNode floor(mozart::VM vm);

  inline
  mozart::UnstableNode log(mozart::VM vm);

  inline
  mozart::UnstableNode round(mozart::VM vm);

  inline
  mozart::UnstableNode sin(mozart::VM vm);

  inline
  mozart::UnstableNode sinh(mozart::VM vm);

  inline
  mozart::UnstableNode sqrt(mozart::VM vm);

  inline
  mozart::UnstableNode tan(mozart::VM vm);

  inline
  mozart::UnstableNode tanh(mozart::VM vm);

  inline
  void printReprToStream(mozart::VM vm, std::ostream & out, int depth, int width);
};
