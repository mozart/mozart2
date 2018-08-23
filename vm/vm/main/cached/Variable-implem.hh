
void TypeInfoOf<Variable>::printReprToStream(VM vm, RichNode self, std::ostream& out,
                    int depth, int width) const {
  assert(self.is<Variable>());
  self.as<Variable>().printReprToStream(vm, out, depth, width);
}

void TypeInfoOf<Variable>::gCollect(GC gc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.make<Variable>(gc->vm, gc, from.access<Variable>());
}

void TypeInfoOf<Variable>::gCollect(GC gc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.make<Variable>(gc->vm, gc, from.access<Variable>());
}

void TypeInfoOf<Variable>::sClone(SC sc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.init(sc->vm, from);
}

void TypeInfoOf<Variable>::sClone(SC sc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.init(sc->vm, from);
}

inline
class mozart::Space *  TypedRichNode<Variable>::home() {
  return _self.access<Variable>().home();
}

inline
void  TypedRichNode<Variable>::addToSuspendList(VM vm, class mozart::RichNode variable) {
  _self.access<Variable>().addToSuspendList(vm, variable);
}

inline
bool  TypedRichNode<Variable>::isNeeded(VM vm) {
  return _self.access<Variable>().isNeeded(vm);
}

inline
void  TypedRichNode<Variable>::markNeeded(VM vm) {
  _self.access<Variable>().markNeeded(vm);
}

inline
void  TypedRichNode<Variable>::wakeUp(VM vm) {
  _self.access<Variable>().wakeUp(_self, vm);
}

inline
bool  TypedRichNode<Variable>::shouldWakeUpUnderSpace(VM vm, class mozart::Space * space) {
  return _self.access<Variable>().shouldWakeUpUnderSpace(vm, space);
}

inline
void  TypedRichNode<Variable>::bind(VM vm, class mozart::RichNode src) {
  _self.access<Variable>().bind(_self, vm, src);
}

inline
void  TypedRichNode<Variable>::printReprToStream(VM vm, std::ostream & out, int depth, int width) {
  _self.access<Variable>().printReprToStream(vm, out, depth, width);
}
