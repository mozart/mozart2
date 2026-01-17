
void TypeInfoOf<Cell>::printReprToStream(VM vm, RichNode self, std::ostream& out,
                    int depth, int width) const {
  assert(self.is<Cell>());
  self.as<Cell>().printReprToStream(vm, out, depth, width);
}

void TypeInfoOf<Cell>::gCollect(GC gc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.make<Cell>(gc->vm, gc, from.access<Cell>());
}

void TypeInfoOf<Cell>::gCollect(GC gc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.make<Cell>(gc->vm, gc, from.access<Cell>());
}

void TypeInfoOf<Cell>::sClone(SC sc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  if (from.as<Cell>().home()->shouldBeCloned()) {
    to.make<Cell>(sc->vm, sc, from.access<Cell>());
  } else {
    to.init(sc->vm, from);
  }
}

void TypeInfoOf<Cell>::sClone(SC sc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  if (from.as<Cell>().home()->shouldBeCloned()) {
    to.make<Cell>(sc->vm, sc, from.access<Cell>());
  } else {
    to.init(sc->vm, from);
  }
}

inline
mozart::Space *  TypedRichNode<Cell>::home() {
  return _self.access<Cell>().home();
}

inline
bool  TypedRichNode<Cell>::isCell(mozart::VM vm) {
  return _self.access<Cell>().isCell(vm);
}

inline
mozart::UnstableNode  TypedRichNode<Cell>::exchange(mozart::VM vm, mozart::RichNode newValue) {
  return _self.access<Cell>().exchange(vm, newValue);
}

inline
mozart::UnstableNode  TypedRichNode<Cell>::access(mozart::VM vm) {
  return _self.access<Cell>().access(vm);
}

inline
void  TypedRichNode<Cell>::assign(mozart::VM vm, mozart::RichNode newValue) {
  _self.access<Cell>().assign(vm, newValue);
}

inline
void  TypedRichNode<Cell>::printReprToStream(mozart::VM vm, std::ostream & out, int depth, int width) {
  _self.access<Cell>().printReprToStream(vm, out, depth, width);
}
