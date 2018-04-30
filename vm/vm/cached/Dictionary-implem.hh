
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
class mozart::Space *  TypedRichNode<Dictionary>::home() {
  return _self.access<Dictionary>().home();
}

inline
bool  TypedRichNode<Dictionary>::lookupFeature(VM vm, class mozart::RichNode feature, nullable<class mozart::UnstableNode &> value) {
  return _self.access<Dictionary>().lookupFeature(vm, feature, value);
}

inline
bool  TypedRichNode<Dictionary>::lookupFeature(VM vm, nativeint feature, nullable<class mozart::UnstableNode &> value) {
  return _self.access<Dictionary>().lookupFeature(vm, feature, value);
}

inline
void  TypedRichNode<Dictionary>::dotAssign(VM vm, class mozart::RichNode feature, class mozart::RichNode newValue) {
  _self.access<Dictionary>().dotAssign(vm, feature, newValue);
}

inline
class mozart::UnstableNode  TypedRichNode<Dictionary>::dotExchange(VM vm, class mozart::RichNode feature, class mozart::RichNode newValue) {
  return _self.access<Dictionary>().dotExchange(_self, vm, feature, newValue);
}

inline
bool  TypedRichNode<Dictionary>::isDictionary(VM vm) {
  return _self.access<Dictionary>().isDictionary(vm);
}

inline
bool  TypedRichNode<Dictionary>::dictIsEmpty(VM vm) {
  return _self.access<Dictionary>().dictIsEmpty(vm);
}

inline
bool  TypedRichNode<Dictionary>::dictMember(VM vm, class mozart::RichNode feature) {
  return _self.access<Dictionary>().dictMember(vm, feature);
}

inline
class mozart::UnstableNode  TypedRichNode<Dictionary>::dictGet(VM vm, class mozart::RichNode feature) {
  return _self.access<Dictionary>().dictGet(_self, vm, feature);
}

inline
class mozart::UnstableNode  TypedRichNode<Dictionary>::dictCondGet(VM vm, class mozart::RichNode feature, class mozart::RichNode defaultValue) {
  return _self.access<Dictionary>().dictCondGet(vm, feature, defaultValue);
}

inline
void  TypedRichNode<Dictionary>::dictPut(VM vm, class mozart::RichNode feature, class mozart::RichNode newValue) {
  _self.access<Dictionary>().dictPut(vm, feature, newValue);
}

inline
class mozart::UnstableNode  TypedRichNode<Dictionary>::dictExchange(VM vm, class mozart::RichNode feature, class mozart::RichNode newValue) {
  return _self.access<Dictionary>().dictExchange(_self, vm, feature, newValue);
}

inline
class mozart::UnstableNode  TypedRichNode<Dictionary>::dictCondExchange(VM vm, class mozart::RichNode feature, class mozart::RichNode defaultValue, class mozart::RichNode newValue) {
  return _self.access<Dictionary>().dictCondExchange(vm, feature, defaultValue, newValue);
}

inline
void  TypedRichNode<Dictionary>::dictRemove(VM vm, class mozart::RichNode feature) {
  _self.access<Dictionary>().dictRemove(vm, feature);
}

inline
void  TypedRichNode<Dictionary>::dictRemoveAll(VM vm) {
  _self.access<Dictionary>().dictRemoveAll(vm);
}

inline
class mozart::UnstableNode  TypedRichNode<Dictionary>::dictKeys(VM vm) {
  return _self.access<Dictionary>().dictKeys(vm);
}

inline
class mozart::UnstableNode  TypedRichNode<Dictionary>::dictEntries(VM vm) {
  return _self.access<Dictionary>().dictEntries(vm);
}

inline
class mozart::UnstableNode  TypedRichNode<Dictionary>::dictItems(VM vm) {
  return _self.access<Dictionary>().dictItems(vm);
}

inline
class mozart::UnstableNode  TypedRichNode<Dictionary>::dictClone(VM vm) {
  return _self.access<Dictionary>().dictClone(vm);
}

inline
void  TypedRichNode<Dictionary>::printReprToStream(VM vm, std::ostream & out, int depth, int width) {
  _self.access<Dictionary>().printReprToStream(vm, out, depth, width);
}

inline
class mozart::NodeDictionary &  TypedRichNode<Dictionary>::getDict() {
  return _self.access<Dictionary>().getDict();
}
