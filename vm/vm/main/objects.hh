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

Implementation<Object>::Implementation(VM vm, size_t attrCount,
                                       StaticArray<UnstableNode> _attributes,
                                       RichNode clazz, RichNode attrModel,
                                       RichNode featModel):
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
      UnstableNode& attr = _attributes[i];
      attr.init(vm, *attrModelRec.getElement(i));

      OpResult res = OpResult::proceed();
      if (matches(vm, res, attr, vm->coreatoms.ooFreeFlag))
        attr = Unbound::build(vm);
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
      feat.init(vm, *featModelRec.getElement(i));

      OpResult res = OpResult::proceed();
      if (matches(vm, res, feat, vm->coreatoms.ooFreeFlag))
        feat.init(vm, Unbound::build(vm));
    }
  }

  _clazz.init(vm, clazz);

  _GsInitialized = false;
}

Implementation<Object>::Implementation(VM vm, size_t attrCount,
                                       StaticArray<UnstableNode> _attributes,
                                       GR gr, Self from):
  WithHome(vm, gr, from->home()) {

  gr->copyStableNode(_attrArity, from->_attrArity);
  _attrCount = from->_attrCount;

  gr->copyStableNode(_clazz, from->_clazz);
  gr->copyStableNode(_features, from->_features);

  for (size_t i = 0; i < attrCount; i++)
    gr->copyUnstableNode(_attributes[i], from[i]);

  _GsInitialized = false;
}

OpResult Implementation<Object>::dot(Self self, VM vm,
                                     RichNode feature, UnstableNode& result) {
  return Dottable(_features).dot(vm, feature, result);
}

OpResult Implementation<Object>::hasFeature(Self self, VM vm, RichNode feature,
                                            bool& result) {
  return Dottable(_features).hasFeature(vm, feature, result);
}

OpResult Implementation<Object>::getClass(Self self, VM vm,
                                          UnstableNode& result) {
  result.copy(vm, _clazz);
  return OpResult::proceed();
}

OpResult Implementation<Object>::attrGet(Self self, VM vm,
                                         RichNode attribute,
                                         UnstableNode& result) {
  size_t offset = 0;
  MOZART_CHECK_OPRESULT(getAttrOffset(self, vm, attribute, offset));

  result.copy(vm, self[offset]);
  return OpResult::proceed();
}

OpResult Implementation<Object>::attrPut(Self self, VM vm,
                                         RichNode attribute,
                                         RichNode value) {
  if (!isHomedInCurrentSpace(vm))
    return raise(vm, MOZART_STR("globalState"), MOZART_STR("object"));

  size_t offset = 0;
  MOZART_CHECK_OPRESULT(getAttrOffset(self, vm, attribute, offset));

  self[offset].copy(vm, value);
  return OpResult::proceed();
}

OpResult Implementation<Object>::attrExchange(Self self, VM vm,
                                              RichNode attribute,
                                              RichNode newValue,
                                              UnstableNode& oldValue) {
  if (!isHomedInCurrentSpace(vm))
    return raise(vm, MOZART_STR("globalState"), MOZART_STR("object"));

  size_t offset = 0;
  MOZART_CHECK_OPRESULT(getAttrOffset(self, vm, attribute, offset));

  oldValue.copy(vm, self[offset]);
  self[offset].copy(vm, newValue);
  return OpResult::proceed();
}

OpResult Implementation<Object>::getAttrOffset(Self self, VM vm,
                                               RichNode attribute,
                                               size_t& offset) {
  return RichNode(_attrArity).as<Arity>().requireFeature(
    vm, self, attribute, offset);
}

OpResult Implementation<Object>::procedureArity(Self self, VM vm, int& result) {
  return Interface<Callable>().procedureArity(self, vm, result);
}

OpResult Implementation<Object>::getCallInfo(
  Self self, VM vm, int& arity,
  ProgramCounter& start, int& Xcount,
  StaticArray<StableNode>& Gs, StaticArray<StableNode>& Ks) {

  if (!_GsInitialized) {
    UnstableNode fallback, fallbackApply;

    UnstableNode ooFallback = trivialBuild(vm, vm->coreatoms.ooFallback);
    MOZART_CHECK_OPRESULT(Dottable(_clazz).dot(vm, ooFallback, fallback));

    UnstableNode apply = trivialBuild(vm, MOZART_STR("apply"));
    MOZART_CHECK_OPRESULT(Dottable(fallback).dot(vm, apply, fallbackApply));

    _Gs[0].init(vm, RichNode(self));
    _Gs[1].init(vm, fallbackApply);

    _GsInitialized = true;
  }

  arity = 1;
  start = dispatchByteCode;
  Xcount = 3;
  Gs = StaticArray<StableNode>(_Gs, 2);
  Ks = nullptr;

  return OpResult::proceed();
}

}

#endif // MOZART_GENERATOR

#endif // __OBJECTS_H
