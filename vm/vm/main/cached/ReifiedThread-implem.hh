
void TypeInfoOf<ReifiedThread>::gCollect(GC gc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.make<ReifiedThread>(gc->vm, gc, from.access<ReifiedThread>());
}

void TypeInfoOf<ReifiedThread>::gCollect(GC gc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.make<ReifiedThread>(gc->vm, gc, from.access<ReifiedThread>());
}

void TypeInfoOf<ReifiedThread>::sClone(SC sc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.make<ReifiedThread>(sc->vm, sc, from.access<ReifiedThread>());
}

void TypeInfoOf<ReifiedThread>::sClone(SC sc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.make<ReifiedThread>(sc->vm, sc, from.access<ReifiedThread>());
}

inline
bool  TypedRichNode<ReifiedThread>::equals(mozart::VM vm, mozart::RichNode right) {
  return _self.access<ReifiedThread>().equals(vm, right);
}

inline
mozart::Runnable *  TypedRichNode<ReifiedThread>::value() {
  return _self.access<ReifiedThread>().value();
}

inline
void  TypedRichNode<ReifiedThread>::wakeUp(mozart::VM vm) {
  _self.access<ReifiedThread>().wakeUp(vm);
}

inline
bool  TypedRichNode<ReifiedThread>::shouldWakeUpUnderSpace(mozart::VM vm, mozart::Space * space) {
  return _self.access<ReifiedThread>().shouldWakeUpUnderSpace(vm, space);
}

inline
bool  TypedRichNode<ReifiedThread>::isThread(mozart::VM vm) {
  return _self.access<ReifiedThread>().isThread(vm);
}

inline
mozart::ThreadPriority  TypedRichNode<ReifiedThread>::getThreadPriority(mozart::VM vm) {
  return _self.access<ReifiedThread>().getThreadPriority(vm);
}

inline
void  TypedRichNode<ReifiedThread>::setThreadPriority(mozart::VM vm, mozart::ThreadPriority priority) {
  _self.access<ReifiedThread>().setThreadPriority(vm, priority);
}

inline
void  TypedRichNode<ReifiedThread>::injectException(mozart::VM vm, mozart::RichNode exception) {
  _self.access<ReifiedThread>().injectException(vm, exception);
}
