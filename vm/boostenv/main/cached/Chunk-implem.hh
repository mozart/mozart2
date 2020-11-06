
void TypeInfoOf<Chunk>::printReprToStream(VM vm, RichNode self, std::ostream& out,
                    int depth, int width) const {
  assert(self.is<Chunk>());
  self.as<Chunk>().printReprToStream(vm, out, depth, width);
}

UnstableNode TypeInfoOf<Chunk>::serialize(VM vm, SE s, RichNode from) const {
  assert(from.is<Chunk>());
  return from.as<Chunk>().serialize(vm, s);
}

void TypeInfoOf<Chunk>::gCollect(GC gc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.make<Chunk>(gc->vm, gc, from.access<Chunk>());
}

void TypeInfoOf<Chunk>::gCollect(GC gc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.make<Chunk>(gc->vm, gc, from.access<Chunk>());
}

void TypeInfoOf<Chunk>::sClone(SC sc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.init(sc->vm, from);
}

void TypeInfoOf<Chunk>::sClone(SC sc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.init(sc->vm, from);
}

inline
mozart::StableNode *  TypedRichNode<Chunk>::getUnderlying() {
  return _self.access<Chunk>().getUnderlying();
}

inline
bool  TypedRichNode<Chunk>::lookupFeature(mozart::VM vm, mozart::RichNode feature, nullable<mozart::UnstableNode &> value) {
  return _self.access<Chunk>().lookupFeature(vm, feature, value);
}

inline
bool  TypedRichNode<Chunk>::lookupFeature(mozart::VM vm, mozart::nativeint feature, nullable<mozart::UnstableNode &> value) {
  return _self.access<Chunk>().lookupFeature(vm, feature, value);
}

inline
bool  TypedRichNode<Chunk>::isChunk(mozart::VM vm) {
  return _self.access<Chunk>().isChunk(vm);
}

inline
void  TypedRichNode<Chunk>::printReprToStream(mozart::VM vm, std::ostream & out, int depth, int width) {
  _self.access<Chunk>().printReprToStream(vm, out, depth, width);
}

inline
mozart::UnstableNode  TypedRichNode<Chunk>::serialize(mozart::VM vm, mozart::SE se) {
  return _self.access<Chunk>().serialize(vm, se);
}
