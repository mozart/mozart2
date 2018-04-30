
void TypeInfoOf<ReifiedGNode>::gCollect(GC gc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.make<ReifiedGNode>(gc->vm, gc, from.access<ReifiedGNode>());
}

void TypeInfoOf<ReifiedGNode>::gCollect(GC gc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.make<ReifiedGNode>(gc->vm, gc, from.access<ReifiedGNode>());
}

void TypeInfoOf<ReifiedGNode>::sClone(SC sc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.make<ReifiedGNode>(sc->vm, sc, from.access<ReifiedGNode>());
}

void TypeInfoOf<ReifiedGNode>::sClone(SC sc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.make<ReifiedGNode>(sc->vm, sc, from.access<ReifiedGNode>());
}

inline
class mozart::GlobalNode *  TypedRichNode<ReifiedGNode>::value() {
  return _self.access<ReifiedGNode>().value();
}

inline
bool  TypedRichNode<ReifiedGNode>::equals(VM vm, class mozart::RichNode right) {
  return _self.access<ReifiedGNode>().equals(vm, right);
}
