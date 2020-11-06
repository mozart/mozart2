
void TypeInfoOf<Float>::printReprToStream(VM vm, RichNode self, std::ostream& out,
                    int depth, int width) const {
  assert(self.is<Float>());
  self.as<Float>().printReprToStream(vm, out, depth, width);
}

void TypeInfoOf<Float>::gCollect(GC gc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.make<Float>(gc->vm, gc, from.access<Float>());
}

void TypeInfoOf<Float>::gCollect(GC gc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.make<Float>(gc->vm, gc, from.access<Float>());
}

void TypeInfoOf<Float>::sClone(SC sc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.make<Float>(sc->vm, sc, from.access<Float>());
}

void TypeInfoOf<Float>::sClone(SC sc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.make<Float>(sc->vm, sc, from.access<Float>());
}

inline
double  TypedRichNode<Float>::value() {
  return _self.access<Float>().value();
}

inline
bool  TypedRichNode<Float>::equals(mozart::VM vm, mozart::RichNode right) {
  return _self.access<Float>().equals(vm, right);
}

inline
int  TypedRichNode<Float>::compare(mozart::VM vm, mozart::RichNode right) {
  return _self.access<Float>().compare(vm, right);
}

inline
bool  TypedRichNode<Float>::isNumber(mozart::VM vm) {
  return _self.access<Float>().isNumber(vm);
}

inline
bool  TypedRichNode<Float>::isInt(mozart::VM vm) {
  return _self.access<Float>().isInt(vm);
}

inline
bool  TypedRichNode<Float>::isFloat(mozart::VM vm) {
  return _self.access<Float>().isFloat(vm);
}

inline
mozart::UnstableNode  TypedRichNode<Float>::opposite(mozart::VM vm) {
  return _self.access<Float>().opposite(vm);
}

inline
mozart::UnstableNode  TypedRichNode<Float>::add(mozart::VM vm, mozart::RichNode right) {
  return _self.access<Float>().add(vm, right);
}

inline
mozart::UnstableNode  TypedRichNode<Float>::add(mozart::VM vm, mozart::nativeint right) {
  return _self.access<Float>().add(_self, vm, right);
}

inline
mozart::UnstableNode  TypedRichNode<Float>::addValue(mozart::VM vm, double b) {
  return _self.access<Float>().addValue(vm, b);
}

inline
mozart::UnstableNode  TypedRichNode<Float>::subtract(mozart::VM vm, mozart::RichNode right) {
  return _self.access<Float>().subtract(vm, right);
}

inline
mozart::UnstableNode  TypedRichNode<Float>::subtractValue(mozart::VM vm, double b) {
  return _self.access<Float>().subtractValue(vm, b);
}

inline
mozart::UnstableNode  TypedRichNode<Float>::multiply(mozart::VM vm, mozart::RichNode right) {
  return _self.access<Float>().multiply(vm, right);
}

inline
mozart::UnstableNode  TypedRichNode<Float>::multiplyValue(mozart::VM vm, double b) {
  return _self.access<Float>().multiplyValue(vm, b);
}

inline
mozart::UnstableNode  TypedRichNode<Float>::divide(mozart::VM vm, mozart::RichNode right) {
  return _self.access<Float>().divide(vm, right);
}

inline
mozart::UnstableNode  TypedRichNode<Float>::divideValue(mozart::VM vm, double b) {
  return _self.access<Float>().divideValue(vm, b);
}

inline
mozart::UnstableNode  TypedRichNode<Float>::fmod(mozart::VM vm, mozart::RichNode right) {
  return _self.access<Float>().fmod(vm, right);
}

inline
mozart::UnstableNode  TypedRichNode<Float>::fmodValue(mozart::VM vm, double b) {
  return _self.access<Float>().fmodValue(vm, b);
}

inline
mozart::UnstableNode  TypedRichNode<Float>::div(mozart::VM vm, mozart::RichNode right) {
  return _self.access<Float>().div(_self, vm, right);
}

inline
mozart::UnstableNode  TypedRichNode<Float>::mod(mozart::VM vm, mozart::RichNode right) {
  return _self.access<Float>().mod(_self, vm, right);
}

inline
mozart::UnstableNode  TypedRichNode<Float>::pow(mozart::VM vm, mozart::RichNode right) {
  return _self.access<Float>().pow(vm, right);
}

inline
mozart::UnstableNode  TypedRichNode<Float>::powValue(mozart::VM vm, double b) {
  return _self.access<Float>().powValue(vm, b);
}

inline
mozart::UnstableNode  TypedRichNode<Float>::abs(mozart::VM vm) {
  return _self.access<Float>().abs(vm);
}

inline
mozart::UnstableNode  TypedRichNode<Float>::acos(mozart::VM vm) {
  return _self.access<Float>().acos(vm);
}

inline
mozart::UnstableNode  TypedRichNode<Float>::acosh(mozart::VM vm) {
  return _self.access<Float>().acosh(vm);
}

inline
mozart::UnstableNode  TypedRichNode<Float>::asin(mozart::VM vm) {
  return _self.access<Float>().asin(vm);
}

inline
mozart::UnstableNode  TypedRichNode<Float>::asinh(mozart::VM vm) {
  return _self.access<Float>().asinh(vm);
}

inline
mozart::UnstableNode  TypedRichNode<Float>::atan(mozart::VM vm) {
  return _self.access<Float>().atan(vm);
}

inline
mozart::UnstableNode  TypedRichNode<Float>::atanh(mozart::VM vm) {
  return _self.access<Float>().atanh(vm);
}

inline
mozart::UnstableNode  TypedRichNode<Float>::atan2(mozart::VM vm, mozart::RichNode right) {
  return _self.access<Float>().atan2(vm, right);
}

inline
mozart::UnstableNode  TypedRichNode<Float>::atan2Value(mozart::VM vm, double b) {
  return _self.access<Float>().atan2Value(vm, b);
}

inline
mozart::UnstableNode  TypedRichNode<Float>::ceil(mozart::VM vm) {
  return _self.access<Float>().ceil(vm);
}

inline
mozart::UnstableNode  TypedRichNode<Float>::cos(mozart::VM vm) {
  return _self.access<Float>().cos(vm);
}

inline
mozart::UnstableNode  TypedRichNode<Float>::cosh(mozart::VM vm) {
  return _self.access<Float>().cosh(vm);
}

inline
mozart::UnstableNode  TypedRichNode<Float>::exp(mozart::VM vm) {
  return _self.access<Float>().exp(vm);
}

inline
mozart::UnstableNode  TypedRichNode<Float>::floor(mozart::VM vm) {
  return _self.access<Float>().floor(vm);
}

inline
mozart::UnstableNode  TypedRichNode<Float>::log(mozart::VM vm) {
  return _self.access<Float>().log(vm);
}

inline
mozart::UnstableNode  TypedRichNode<Float>::round(mozart::VM vm) {
  return _self.access<Float>().round(vm);
}

inline
mozart::UnstableNode  TypedRichNode<Float>::sin(mozart::VM vm) {
  return _self.access<Float>().sin(vm);
}

inline
mozart::UnstableNode  TypedRichNode<Float>::sinh(mozart::VM vm) {
  return _self.access<Float>().sinh(vm);
}

inline
mozart::UnstableNode  TypedRichNode<Float>::sqrt(mozart::VM vm) {
  return _self.access<Float>().sqrt(vm);
}

inline
mozart::UnstableNode  TypedRichNode<Float>::tan(mozart::VM vm) {
  return _self.access<Float>().tan(vm);
}

inline
mozart::UnstableNode  TypedRichNode<Float>::tanh(mozart::VM vm) {
  return _self.access<Float>().tanh(vm);
}

inline
void  TypedRichNode<Float>::printReprToStream(mozart::VM vm, std::ostream & out, int depth, int width) {
  _self.access<Float>().printReprToStream(vm, out, depth, width);
}
