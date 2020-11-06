
void TypeInfoOf<String>::printReprToStream(VM vm, RichNode self, std::ostream& out,
                    int depth, int width) const {
  assert(self.is<String>());
  self.as<String>().printReprToStream(vm, out, depth, width);
}

void TypeInfoOf<String>::gCollect(GC gc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.make<String>(gc->vm, gc, from.access<String>());
}

void TypeInfoOf<String>::gCollect(GC gc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.make<String>(gc->vm, gc, from.access<String>());
}

void TypeInfoOf<String>::sClone(SC sc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.make<String>(sc->vm, sc, from.access<String>());
}

void TypeInfoOf<String>::sClone(SC sc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.make<String>(sc->vm, sc, from.access<String>());
}

inline
const LString<char> &  TypedRichNode<String>::value() {
  return _self.access<String>().value();
}

inline
bool  TypedRichNode<String>::equals(mozart::VM vm, mozart::RichNode right) {
  return _self.access<String>().equals(vm, right);
}

inline
int  TypedRichNode<String>::compare(mozart::VM vm, mozart::RichNode right) {
  return _self.access<String>().compare(vm, right);
}

inline
bool  TypedRichNode<String>::isString(mozart::VM vm) {
  return _self.access<String>().isString(vm);
}

inline
bool  TypedRichNode<String>::isByteString(mozart::VM vm) {
  return _self.access<String>().isByteString(vm);
}

inline
LString<char> *  TypedRichNode<String>::stringGet(mozart::VM vm) {
  return _self.access<String>().stringGet(vm);
}

inline
LString<unsigned char> *  TypedRichNode<String>::byteStringGet(mozart::VM vm) {
  return _self.access<String>().byteStringGet(_self, vm);
}

inline
mozart::nativeint  TypedRichNode<String>::stringCharAt(mozart::VM vm, mozart::RichNode offset) {
  return _self.access<String>().stringCharAt(_self, vm, offset);
}

inline
mozart::UnstableNode  TypedRichNode<String>::stringAppend(mozart::VM vm, mozart::RichNode right) {
  return _self.access<String>().stringAppend(_self, vm, right);
}

inline
mozart::UnstableNode  TypedRichNode<String>::stringSlice(mozart::VM vm, mozart::RichNode from, mozart::RichNode to) {
  return _self.access<String>().stringSlice(_self, vm, from, to);
}

inline
void  TypedRichNode<String>::stringSearch(mozart::VM vm, mozart::RichNode from, mozart::RichNode needle, mozart::UnstableNode & begin, mozart::UnstableNode & end) {
  _self.access<String>().stringSearch(_self, vm, from, needle, begin, end);
}

inline
bool  TypedRichNode<String>::stringHasPrefix(mozart::VM vm, mozart::RichNode prefix) {
  return _self.access<String>().stringHasPrefix(vm, prefix);
}

inline
bool  TypedRichNode<String>::stringHasSuffix(mozart::VM vm, mozart::RichNode suffix) {
  return _self.access<String>().stringHasSuffix(vm, suffix);
}

inline
bool  TypedRichNode<String>::lookupFeature(mozart::VM vm, mozart::RichNode feature, nullable<mozart::UnstableNode &> value) {
  return _self.access<String>().lookupFeature(_self, vm, feature, value);
}

inline
bool  TypedRichNode<String>::lookupFeature(mozart::VM vm, mozart::nativeint feature, nullable<mozart::UnstableNode &> value) {
  return _self.access<String>().lookupFeature(_self, vm, feature, value);
}

inline
void  TypedRichNode<String>::printReprToStream(mozart::VM vm, std::ostream & out, int depth, int width) {
  _self.access<String>().printReprToStream(vm, out, depth, width);
}
