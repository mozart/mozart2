// Copyright © 2011, Université catholique de Louvain
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// *  Redistributions of source code must retain the above copyright notice,
//    this list of conditions and the following disclaimer.
// *  Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

#ifndef __OBJECTS_H
#define __OBJECTS_H

#include "mozartcore.hh"

#ifndef MOZART_GENERATOR

namespace mozart {

////////////
// Object //
////////////

#include "Object-implem.hh"

Object::Object(VM vm, size_t attrCount, RichNode clazz,
               RichNode attrModel, RichNode featModel):
  WithHome(vm) {

  using namespace patternmatching;

  assert(attrModel.is<Atom>() || attrModel.is<Record>());
  assert(featModel.is<Atom>() || featModel.is<Record>());

  // Initialize attributes
  if (attrModel.is<Atom>()) {
    assert(attrCount == 0);
    _attrArity.init(vm, Unit::build(vm));
    _attrCount = 0;
  } else {
    auto attrModelRec = attrModel.as<Record>();
    assert(attrModelRec.getWidth() >= 0);
    assert(attrCount == (size_t) attrModelRec.getWidth());

    _attrArity.init(vm, *attrModelRec.getArity());
    _attrCount = attrCount;

    for (size_t i = 0; i < attrCount; i++) {
      UnstableNode& attr = getElements(i);

      if (isFreeFlag(vm, *attrModelRec.getElement(i)))
        attr.init(vm, OptVar::build(vm));
      else
        attr.init(vm, *attrModelRec.getElement(i));
    }
  }

  // Initialize features
  if (featModel.is<Atom>()) {
    _features.init(vm, Unit::build(vm));
  } else {
    auto featModelRec = featModel.as<Record>();
    size_t featCount = featModelRec.getWidth();

    _features.init(vm, Record::build(vm, featCount, *featModelRec.getArity()));
    auto _featuresRec = RichNode(_features).as<Record>();

    for (size_t i = 0; i < featCount; i++) {
      StableNode& feat = *_featuresRec.getElement(i);

      if (isFreeFlag(vm, *featModelRec.getElement(i)))
        feat.init(vm, OptVar::build(vm));
      else
        feat.init(vm, *featModelRec.getElement(i));
    }
  }

  _clazz.init(vm, clazz);

  _GsInitialized = false;
}

Object::Object(VM vm, size_t attrCount, GR gr, Object& from):
  WithHome(vm, gr, from) {

  gr->copyStableNode(_attrArity, from._attrArity);
  _attrCount = from._attrCount;

  gr->copyStableNode(_clazz, from._clazz);
  gr->copyStableNode(_features, from._features);

  gr->copyUnstableNodes(getElementsArray(), from.getElementsArray(), attrCount);

  _GsInitialized = false;
}

bool Object::isFreeFlag(VM vm, RichNode value) {
  return value.is<UniqueName>() &&
    (value.as<UniqueName>().value() == vm->coreatoms.ooFreeFlag);
}

bool Object::lookupFeature(VM vm, RichNode feature,
                           nullable<UnstableNode&> value) {
  return Dottable(_features).lookupFeature(vm, feature, value);
}

bool Object::lookupFeature(VM vm, nativeint feature,
                           nullable<UnstableNode&> value) {
  return Dottable(_features).lookupFeature(vm, feature, value);
}

UnstableNode Object::getClass(VM vm) {
  return { vm, _clazz };
}

UnstableNode Object::attrGet(RichNode self, VM vm, RichNode attribute) {
  return { vm, getElements(getAttrOffset(self, vm, attribute)) };
}

void Object::attrPut(RichNode self, VM vm, RichNode attribute, RichNode value) {
  if (!isHomedInCurrentSpace(vm))
    return raise(vm, MOZART_STR("globalState"), MOZART_STR("object"));

  getElements(getAttrOffset(self, vm, attribute)).copy(vm, value);
}

UnstableNode Object::attrExchange(RichNode self, VM vm, RichNode attribute,
                                  RichNode newValue) {
  if (!isHomedInCurrentSpace(vm))
    raise(vm, MOZART_STR("globalState"), MOZART_STR("object"));

  auto& element = getElements(getAttrOffset(self, vm, attribute));

  UnstableNode oldValue = std::move(element);
  element.copy(vm, newValue);
  return oldValue;
}

size_t Object::getAttrOffset(RichNode self, VM vm, RichNode attribute) {
  size_t result;
  if (RichNode(_attrArity).as<Arity>().lookupFeature(vm, attribute, result)) {
    return result;
  } else {
    raiseError(vm, MOZART_STR("object"), MOZART_STR("@"), self, attribute);
  }
}

size_t Object::procedureArity(RichNode self, VM vm) {
  return Interface<Callable>().procedureArity(self, vm);
}

void Object::getCallInfo(
  RichNode self, VM vm, size_t& arity,
  ProgramCounter& start, size_t& Xcount,
  StaticArray<StableNode>& Gs, StaticArray<StableNode>& Ks) {

  if (!_GsInitialized) {
    auto ooFallback = mozart::build(vm, vm->coreatoms.ooFallback);
    auto fallback = Dottable(_clazz).dot(vm, ooFallback);

    auto apply = mozart::build(vm, MOZART_STR("apply"));
    auto fallbackApply = Dottable(fallback).dot(vm, apply);

    _Gs[0].init(vm, self);
    _Gs[1].init(vm, fallbackApply);

    _GsInitialized = true;
  }

  arity = 1;
  start = dispatchByteCode;
  Xcount = 3;
  Gs = StaticArray<StableNode>(_Gs, 2);
  Ks = nullptr;
}

void Object::getDebugInfo(VM vm, atom_t& printName, UnstableNode& debugData) {
  printName = vm->getAtom(MOZART_STR("<Object>"));
  debugData = mozart::build(vm, unit);
}

}

#endif // MOZART_GENERATOR

#endif // __OBJECTS_H
