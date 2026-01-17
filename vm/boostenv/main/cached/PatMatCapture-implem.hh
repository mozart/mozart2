
void TypeInfoOf<PatMatCapture>::printReprToStream(VM vm, RichNode self, std::ostream& out,
                    int depth, int width) const {
  assert(self.is<PatMatCapture>());
  self.as<PatMatCapture>().printReprToStream(vm, out, depth, width);
}

UnstableNode TypeInfoOf<PatMatCapture>::serialize(VM vm, SE s, RichNode from) const {
  assert(from.is<PatMatCapture>());
  return from.as<PatMatCapture>().serialize(vm, s);
}

void TypeInfoOf<PatMatCapture>::gCollect(GC gc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.make<PatMatCapture>(gc->vm, gc, from.access<PatMatCapture>());
}

void TypeInfoOf<PatMatCapture>::gCollect(GC gc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.make<PatMatCapture>(gc->vm, gc, from.access<PatMatCapture>());
}

void TypeInfoOf<PatMatCapture>::sClone(SC sc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.make<PatMatCapture>(sc->vm, sc, from.access<PatMatCapture>());
}

void TypeInfoOf<PatMatCapture>::sClone(SC sc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.make<PatMatCapture>(sc->vm, sc, from.access<PatMatCapture>());
}

inline
mozart::nativeint  TypedRichNode<PatMatCapture>::index() {
  return _self.access<PatMatCapture>().index();
}

inline
bool  TypedRichNode<PatMatCapture>::equals(mozart::VM vm, mozart::RichNode right) {
  return _self.access<PatMatCapture>().equals(vm, right);
}

inline
void  TypedRichNode<PatMatCapture>::printReprToStream(mozart::VM vm, std::ostream & out, int depth, int width) {
  _self.access<PatMatCapture>().printReprToStream(vm, out, depth, width);
}

inline
mozart::UnstableNode  TypedRichNode<PatMatCapture>::serialize(mozart::VM vm, mozart::SE se) {
  return _self.access<PatMatCapture>().serialize(vm, se);
}
