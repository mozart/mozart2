
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
bool  TypedRichNode<Float>::equals(VM vm, class mozart::RichNode right) {
  return _self.access<Float>().equals(vm, right);
}

inline
int  TypedRichNode<Float>::compare(VM vm, class mozart::RichNode right) {
  return _self.access<Float>().compare(vm, right);
}

inline
bool  TypedRichNode<Float>::isNumber(VM vm) {
  return _self.access<Float>().isNumber(vm);
}

inline
bool  TypedRichNode<Float>::isInt(VM vm) {
  return _self.access<Float>().isInt(vm);
}

inline
bool  TypedRichNode<Float>::isFloat(VM vm) {
  return _self.access<Float>().isFloat(vm);
}

inline
class mozart::UnstableNode  TypedRichNode<Float>::opposite(VM vm) {
  return _self.access<Float>().opposite(vm);
}

inline
class mozart::UnstableNode  TypedRichNode<Float>::add(VM vm, class mozart::RichNode right) {
  return _self.access<Float>().add(vm, right);
}

inline
class mozart::UnstableNode  TypedRichNode<Float>::add(VM vm, nativeint right) {
  return _self.access<Float>().add(_self, vm, right);
}

inline
class mozart::UnstableNode  TypedRichNode<Float>::addValue(VM vm, double b) {
  return _self.access<Float>().addValue(vm, b);
}

inline
class mozart::UnstableNode  TypedRichNode<Float>::subtract(VM vm, class mozart::RichNode right) {
  return _self.access<Float>().subtract(vm, right);
}

inline
class mozart::UnstableNode  TypedRichNode<Float>::subtractValue(VM vm, double b) {
  return _self.access<Float>().subtractValue(vm, b);
}

inline
class mozart::UnstableNode  TypedRichNode<Float>::multiply(VM vm, class mozart::RichNode right) {
  return _self.access<Float>().multiply(vm, right);
}

inline
class mozart::UnstableNode  TypedRichNode<Float>::multiplyValue(VM vm, double b) {
  return _self.access<Float>().multiplyValue(vm, b);
}

inline
class mozart::UnstableNode  TypedRichNode<Float>::divide(VM vm, class mozart::RichNode right) {
  return _self.access<Float>().divide(vm, right);
}

inline
class mozart::UnstableNode  TypedRichNode<Float>::divideValue(VM vm, double b) {
  return _self.access<Float>().divideValue(vm, b);
}

inline
class mozart::UnstableNode  TypedRichNode<Float>::fmod(VM vm, class mozart::RichNode right) {
  return _self.access<Float>().fmod(vm, right);
}

inline
class mozart::UnstableNode  TypedRichNode<Float>::fmodValue(VM vm, double b) {
  return _self.access<Float>().fmodValue(vm, b);
}

inline
class mozart::UnstableNode  TypedRichNode<Float>::div(VM vm, class mozart::RichNode right) {
  return _self.access<Float>().div(_self, vm, right);
}

inline
class mozart::UnstableNode  TypedRichNode<Float>::mod(VM vm, class mozart::RichNode right) {
  return _self.access<Float>().mod(_self, vm, right);
}

inline
class mozart::UnstableNode  TypedRichNode<Float>::pow(VM vm, class mozart::RichNode right) {
  return _self.access<Float>().pow(vm, right);
}

inline
class mozart::UnstableNode  TypedRichNode<Float>::powValue(VM vm, double b) {
  return _self.access<Float>().powValue(vm, b);
}

inline
class mozart::UnstableNode  TypedRichNode<Float>::abs(VM vm) {
  return _self.access<Float>().abs(vm);
}

inline
class mozart::UnstableNode  TypedRichNode<Float>::acos(VM vm) {
  return _self.access<Float>().acos(vm);
}

inline
class mozart::UnstableNode  TypedRichNode<Float>::acosh(VM vm) {
  return _self.access<Float>().acosh(vm);
}

inline
class mozart::UnstableNode  TypedRichNode<Float>::asin(VM vm) {
  return _self.access<Float>().asin(vm);
}

inline
class mozart::UnstableNode  TypedRichNode<Float>::asinh(VM vm) {
  return _self.access<Float>().asinh(vm);
}

inline
class mozart::UnstableNode  TypedRichNode<Float>::atan(VM vm) {
  return _self.access<Float>().atan(vm);
}

inline
class mozart::UnstableNode  TypedRichNode<Float>::atanh(VM vm) {
  return _self.access<Float>().atanh(vm);
}

inline
class mozart::UnstableNode  TypedRichNode<Float>::atan2(VM vm, class mozart::RichNode right) {
  return _self.access<Float>().atan2(vm, right);
}

inline
class mozart::UnstableNode  TypedRichNode<Float>::atan2Value(VM vm, double b) {
  return _self.access<Float>().atan2Value(vm, b);
}

inline
class mozart::UnstableNode  TypedRichNode<Float>::ceil(VM vm) {
  return _self.access<Float>().ceil(vm);
}

inline
class mozart::UnstableNode  TypedRichNode<Float>::cos(VM vm) {
  return _self.access<Float>().cos(vm);
}

inline
class mozart::UnstableNode  TypedRichNode<Float>::cosh(VM vm) {
  return _self.access<Float>().cosh(vm);
}

inline
class mozart::UnstableNode  TypedRichNode<Float>::exp(VM vm) {
  return _self.access<Float>().exp(vm);
}

inline
class mozart::UnstableNode  TypedRichNode<Float>::floor(VM vm) {
  return _self.access<Float>().floor(vm);
}

inline
class mozart::UnstableNode  TypedRichNode<Float>::log(VM vm) {
  return _self.access<Float>().log(vm);
}

inline
class mozart::UnstableNode  TypedRichNode<Float>::round(VM vm) {
  return _self.access<Float>().round(vm);
}

inline
class mozart::UnstableNode  TypedRichNode<Float>::sin(VM vm) {
  return _self.access<Float>().sin(vm);
}

inline
class mozart::UnstableNode  TypedRichNode<Float>::sinh(VM vm) {
  return _self.access<Float>().sinh(vm);
}

inline
class mozart::UnstableNode  TypedRichNode<Float>::sqrt(VM vm) {
  return _self.access<Float>().sqrt(vm);
}

inline
class mozart::UnstableNode  TypedRichNode<Float>::tan(VM vm) {
  return _self.access<Float>().tan(vm);
}

inline
class mozart::UnstableNode  TypedRichNode<Float>::tanh(VM vm) {
  return _self.access<Float>().tanh(vm);
}

inline
void  TypedRichNode<Float>::printReprToStream(VM vm, std::ostream & out, int depth, int width) {
  _self.access<Float>().printReprToStream(vm, out, depth, width);
}
