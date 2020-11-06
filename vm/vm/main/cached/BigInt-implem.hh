
void TypeInfoOf<BigInt>::printReprToStream(VM vm, RichNode self, std::ostream& out,
                    int depth, int width) const {
  assert(self.is<BigInt>());
  self.as<BigInt>().printReprToStream(vm, out, depth, width);
}

void TypeInfoOf<BigInt>::gCollect(GC gc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.make<BigInt>(gc->vm, gc, from.access<BigInt>());
}

void TypeInfoOf<BigInt>::gCollect(GC gc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.make<BigInt>(gc->vm, gc, from.access<BigInt>());
}

void TypeInfoOf<BigInt>::sClone(SC sc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.make<BigInt>(sc->vm, sc, from.access<BigInt>());
}

void TypeInfoOf<BigInt>::sClone(SC sc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.make<BigInt>(sc->vm, sc, from.access<BigInt>());
}

int TypeInfoOf<BigInt>::compareFeatures(VM vm, RichNode lhs, RichNode rhs) const {
  return lhs.as<BigInt>().compareFeatures(vm, rhs);
}


inline
std::shared_ptr<BigIntImplem>  TypedRichNode<BigInt>::value() {
  return _self.access<BigInt>().value();
}

inline
bool  TypedRichNode<BigInt>::equals(mozart::VM vm, mozart::RichNode right) {
  return _self.access<BigInt>().equals(vm, right);
}

inline
int  TypedRichNode<BigInt>::compareFeatures(mozart::VM vm, mozart::RichNode right) {
  return _self.access<BigInt>().compareFeatures(vm, right);
}

inline
int  TypedRichNode<BigInt>::compare(mozart::VM vm, mozart::RichNode right) {
  return _self.access<BigInt>().compare(vm, right);
}

inline
bool  TypedRichNode<BigInt>::isNumber(mozart::VM vm) {
  return _self.access<BigInt>().isNumber(vm);
}

inline
bool  TypedRichNode<BigInt>::isInt(mozart::VM vm) {
  return _self.access<BigInt>().isInt(vm);
}

inline
bool  TypedRichNode<BigInt>::isFloat(mozart::VM vm) {
  return _self.access<BigInt>().isFloat(vm);
}

inline
mozart::UnstableNode  TypedRichNode<BigInt>::opposite(mozart::VM vm) {
  return _self.access<BigInt>().opposite(vm);
}

inline
mozart::UnstableNode  TypedRichNode<BigInt>::add(mozart::VM vm, mozart::RichNode right) {
  return _self.access<BigInt>().add(vm, right);
}

inline
mozart::UnstableNode  TypedRichNode<BigInt>::add(mozart::VM vm, mozart::nativeint b) {
  return _self.access<BigInt>().add(vm, b);
}

inline
mozart::UnstableNode  TypedRichNode<BigInt>::subtract(mozart::VM vm, mozart::RichNode right) {
  return _self.access<BigInt>().subtract(vm, right);
}

inline
mozart::UnstableNode  TypedRichNode<BigInt>::multiply(mozart::VM vm, mozart::RichNode right) {
  return _self.access<BigInt>().multiply(vm, right);
}

inline
mozart::UnstableNode  TypedRichNode<BigInt>::div(mozart::VM vm, mozart::RichNode right) {
  return _self.access<BigInt>().div(vm, right);
}

inline
mozart::UnstableNode  TypedRichNode<BigInt>::mod(mozart::VM vm, mozart::RichNode right) {
  return _self.access<BigInt>().mod(vm, right);
}

inline
mozart::UnstableNode  TypedRichNode<BigInt>::abs(mozart::VM vm) {
  return _self.access<BigInt>().abs(_self, vm);
}

inline
double  TypedRichNode<BigInt>::doubleValue() {
  return _self.access<BigInt>().doubleValue();
}

inline
std::string  TypedRichNode<BigInt>::str() {
  return _self.access<BigInt>().str();
}

inline
void  TypedRichNode<BigInt>::printReprToStream(mozart::VM vm, std::ostream & out, int depth, int width) {
  _self.access<BigInt>().printReprToStream(vm, out, depth, width);
}
