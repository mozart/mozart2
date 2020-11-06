
void TypeInfoOf<ByteString>::printReprToStream(VM vm, RichNode self, std::ostream& out,
                    int depth, int width) const {
  assert(self.is<ByteString>());
  self.as<ByteString>().printReprToStream(vm, out, depth, width);
}

void TypeInfoOf<ByteString>::gCollect(GC gc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.make<ByteString>(gc->vm, gc, from.access<ByteString>());
}

void TypeInfoOf<ByteString>::gCollect(GC gc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.make<ByteString>(gc->vm, gc, from.access<ByteString>());
}

void TypeInfoOf<ByteString>::sClone(SC sc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.make<ByteString>(sc->vm, sc, from.access<ByteString>());
}

void TypeInfoOf<ByteString>::sClone(SC sc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.make<ByteString>(sc->vm, sc, from.access<ByteString>());
}

inline
bool  TypedRichNode<ByteString>::lookupFeature(mozart::VM vm, mozart::RichNode feature, nullable<mozart::UnstableNode &> value) {
  return _self.access<ByteString>().lookupFeature(vm, feature, value);
}

inline
bool  TypedRichNode<ByteString>::lookupFeature(mozart::VM vm, mozart::nativeint feature, nullable<mozart::UnstableNode &> value) {
  return _self.access<ByteString>().lookupFeature(vm, feature, value);
}

inline
const LString<unsigned char> &  TypedRichNode<ByteString>::value() {
  return _self.access<ByteString>().value();
}

inline
bool  TypedRichNode<ByteString>::equals(mozart::VM vm, mozart::RichNode right) {
  return _self.access<ByteString>().equals(vm, right);
}

inline
int  TypedRichNode<ByteString>::compare(mozart::VM vm, mozart::RichNode right) {
  return _self.access<ByteString>().compare(vm, right);
}

inline
bool  TypedRichNode<ByteString>::isString(mozart::VM vm) {
  return _self.access<ByteString>().isString(vm);
}

inline
bool  TypedRichNode<ByteString>::isByteString(mozart::VM vm) {
  return _self.access<ByteString>().isByteString(vm);
}

inline
LString<char> *  TypedRichNode<ByteString>::stringGet(mozart::VM vm) {
  return _self.access<ByteString>().stringGet(_self, vm);
}

inline
LString<unsigned char> *  TypedRichNode<ByteString>::byteStringGet(mozart::VM vm) {
  return _self.access<ByteString>().byteStringGet(vm);
}

inline
mozart::nativeint  TypedRichNode<ByteString>::stringCharAt(mozart::VM vm, mozart::RichNode offset) {
  return _self.access<ByteString>().stringCharAt(_self, vm, offset);
}

inline
mozart::UnstableNode  TypedRichNode<ByteString>::stringAppend(mozart::VM vm, mozart::RichNode right) {
  return _self.access<ByteString>().stringAppend(_self, vm, right);
}

inline
mozart::UnstableNode  TypedRichNode<ByteString>::stringSlice(mozart::VM vm, mozart::RichNode from, mozart::RichNode to) {
  return _self.access<ByteString>().stringSlice(_self, vm, from, to);
}

inline
void  TypedRichNode<ByteString>::stringSearch(mozart::VM vm, mozart::RichNode from, mozart::RichNode needle, mozart::UnstableNode & begin, mozart::UnstableNode & end) {
  _self.access<ByteString>().stringSearch(_self, vm, from, needle, begin, end);
}

inline
bool  TypedRichNode<ByteString>::stringHasPrefix(mozart::VM vm, mozart::RichNode prefix) {
  return _self.access<ByteString>().stringHasPrefix(vm, prefix);
}

inline
bool  TypedRichNode<ByteString>::stringHasSuffix(mozart::VM vm, mozart::RichNode suffix) {
  return _self.access<ByteString>().stringHasSuffix(vm, suffix);
}

inline
void  TypedRichNode<ByteString>::printReprToStream(mozart::VM vm, std::ostream & out, int depth, int width) {
  _self.access<ByteString>().printReprToStream(vm, out, depth, width);
}
