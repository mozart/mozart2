
void TypeInfoOf<ReifiedThread>::gCollect(GC gc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.make<ReifiedThread>(gc->vm, gc, from.access<ReifiedThread>());
}

void TypeInfoOf<ReifiedThread>::gCollect(GC gc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  StableNode* stable = new (gc->vm) StableNode;
  to.make<Reference>(gc->vm, stable);
  stable->make<ReifiedThread>(gc->vm, gc, from.access<ReifiedThread>());
}

void TypeInfoOf<ReifiedThread>::sClone(SC sc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.make<ReifiedThread>(sc->vm, sc, from.access<ReifiedThread>());
}

void TypeInfoOf<ReifiedThread>::sClone(SC sc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  StableNode* stable = new (sc->vm) StableNode;
to.make<Reference>(sc->vm, stable);
stable->make<ReifiedThread>(sc->vm, sc, from.access<ReifiedThread>());
}

inline
bool  TypedRichNode<ReifiedThread>::equals(VM vm, class mozart::RichNode right) {
  return _self.access<ReifiedThread>().equals(vm, right);
}

inline
class mozart::Runnable *  TypedRichNode<ReifiedThread>::value() {
  return _self.access<ReifiedThread>().value();
}

inline
void  TypedRichNode<ReifiedThread>::wakeUp(VM vm) {
  _self.access<ReifiedThread>().wakeUp(vm);
}

inline
bool  TypedRichNode<ReifiedThread>::shouldWakeUpUnderSpace(VM vm, class mozart::Space * space) {
  return _self.access<ReifiedThread>().shouldWakeUpUnderSpace(vm, space);
}

inline
bool  TypedRichNode<ReifiedThread>::isThread(VM vm) {
  return _self.access<ReifiedThread>().isThread(vm);
}

inline
enum mozart::ThreadPriority  TypedRichNode<ReifiedThread>::getThreadPriority(VM vm) {
  return _self.access<ReifiedThread>().getThreadPriority(vm);
}

inline
void  TypedRichNode<ReifiedThread>::setThreadPriority(VM vm, enum mozart::ThreadPriority priority) {
  _self.access<ReifiedThread>().setThreadPriority(vm, priority);
}

inline
void  TypedRichNode<ReifiedThread>::injectException(VM vm, class mozart::RichNode exception) {
  _self.access<ReifiedThread>().injectException(vm, exception);
}
