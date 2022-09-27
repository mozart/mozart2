
void TypeInfoOf<Dictionary>::printReprToStream(VM vm, RichNode self, std::ostream& out,
                    int depth, int width) const {
  assert(self.is<Dictionary>());
  self.as<Dictionary>().printReprToStream(vm, out, depth, width);
}

void TypeInfoOf<Dictionary>::gCollect(GC gc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  to.make<Dictionary>(gc->vm, gc, from.access<Dictionary>());
}

void TypeInfoOf<Dictionary>::gCollect(GC gc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  to.make<Dictionary>(gc->vm, gc, from.access<Dictionary>());
}

void TypeInfoOf<Dictionary>::sClone(SC sc, RichNode from, StableNode& to) const {
  assert(from.type() == type());
  if (from.as<Dictionary>().home()->shouldBeCloned()) {
    to.make<Dictionary>(sc->vm, sc, from.access<Dictionary>());
  } else {
    to.init(sc->vm, from);
  }
}

void TypeInfoOf<Dictionary>::sClone(SC sc, RichNode from, UnstableNode& to) const {
  assert(from.type() == type());
  if (from.as<Dictionary>().home()->shouldBeCloned()) {
    to.make<Dictionary>(sc->vm, sc, from.access<Dictionary>());
  } else {
    to.init(sc->vm, from);
  }
}

inline
mozart::Space *  TypedRichNode<Dictionary>::home() {
  return _self.access<Dictionary>().home();
}

inline
bool  TypedRichNode<Dictionary>::lookupFeature(mozart::VM vm, mozart::RichNode feature, nullable<mozart::UnstableNode &> value) {
  return _self.access<Dictionary>().lookupFeature(vm, feature, value);
}

inline
bool  TypedRichNode<Dictionary>::lookupFeature(mozart::VM vm, mozart::nativeint feature, nullable<mozart::UnstableNode &> value) {
  return _self.access<Dictionary>().lookupFeature(vm, feature, value);
}

inline
void  TypedRichNode<Dictionary>::dotAssign(mozart::VM vm, mozart::RichNode feature, mozart::RichNode newValue) {
  _self.access<Dictionary>().dotAssign(vm, feature, newValue);
}

inline
mozart::UnstableNode  TypedRichNode<Dictionary>::dotExchange(mozart::VM vm, mozart::RichNode feature, mozart::RichNode newValue) {
  return _self.access<Dictionary>().dotExchange(_self, vm, feature, newValue);
}

inline
bool  TypedRichNode<Dictionary>::isDictionary(mozart::VM vm) {
  return _self.access<Dictionary>().isDictionary(vm);
}

inline
bool  TypedRichNode<Dictionary>::dictIsEmpty(mozart::VM vm) {
  return _self.access<Dictionary>().dictIsEmpty(vm);
}

inline
bool  TypedRichNode<Dictionary>::dictMember(mozart::VM vm, mozart::RichNode feature) {
  return _self.access<Dictionary>().dictMember(vm, feature);
}

inline
mozart::UnstableNode  TypedRichNode<Dictionary>::dictGet(mozart::VM vm, mozart::RichNode feature) {
  return _self.access<Dictionary>().dictGet(_self, vm, feature);
}

inline
mozart::UnstableNode  TypedRichNode<Dictionary>::dictCondGet(mozart::VM vm, mozart::RichNode feature, mozart::RichNode defaultValue) {
  return _self.access<Dictionary>().dictCondGet(vm, feature, defaultValue);
}

inline
void  TypedRichNode<Dictionary>::dictPut(mozart::VM vm, mozart::RichNode feature, mozart::RichNode newValue) {
  _self.access<Dictionary>().dictPut(vm, feature, newValue);
}

inline
mozart::UnstableNode  TypedRichNode<Dictionary>::dictExchange(mozart::VM vm, mozart::RichNode feature, mozart::RichNode newValue) {
  return _self.access<Dictionary>().dictExchange(_self, vm, feature, newValue);
}

inline
mozart::UnstableNode  TypedRichNode<Dictionary>::dictCondExchange(mozart::VM vm, mozart::RichNode feature, mozart::RichNode defaultValue, mozart::RichNode newValue) {
  return _self.access<Dictionary>().dictCondExchange(vm, feature, defaultValue, newValue);
}

inline
void  TypedRichNode<Dictionary>::dictRemove(mozart::VM vm, mozart::RichNode feature) {
  _self.access<Dictionary>().dictRemove(vm, feature);
}

inline
void  TypedRichNode<Dictionary>::dictRemoveAll(mozart::VM vm) {
  _self.access<Dictionary>().dictRemoveAll(vm);
}

inline
mozart::UnstableNode  TypedRichNode<Dictionary>::dictKeys(mozart::VM vm) {
  return _self.access<Dictionary>().dictKeys(vm);
}

inline
mozart::UnstableNode  TypedRichNode<Dictionary>::dictEntries(mozart::VM vm) {
  return _self.access<Dictionary>().dictEntries(vm);
}

inline
mozart::UnstableNode  TypedRichNode<Dictionary>::dictItems(mozart::VM vm) {
  return _self.access<Dictionary>().dictItems(vm);
}

inline
mozart::UnstableNode  TypedRichNode<Dictionary>::dictClone(mozart::VM vm) {
  return _self.access<Dictionary>().dictClone(vm);
}

inline
void  TypedRichNode<Dictionary>::printReprToStream(mozart::VM vm, std::ostream & out, int depth, int width) {
  _self.access<Dictionary>().printReprToStream(vm, out, depth, width);
}

inline
mozart::NodeDictionary &  TypedRichNode<Dictionary>::getDict() {
  return _self.access<Dictionary>().getDict();
}
