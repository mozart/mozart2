// Copyright © 2012, Université catholique de Louvain
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

#include "mozart.hh"

namespace mozart {

struct SuspendTrailEntry {
  SuspendTrailEntry(StableNode* left, StableNode* right) :
    left(left), right(right) {}

  StableNode* left;
  StableNode* right;
};

typedef VMAllocatedList<SuspendTrailEntry> SuspendTrail;

typedef VMAllocatedList<NodeBackup> RebindTrail;

struct StructuralDualWalk {
public:
  enum Kind {
    wkUnify, wkEquals, wkPatternMatch
  };
public:
  StructuralDualWalk(VM vm, Kind kind,
                     StaticArray<UnstableNode> captures = nullptr):
    vm(vm), kind(kind), captures(captures) {}

  OpResult run(RichNode left, RichNode right);
private:
  inline
  OpResult processPair(VM vm, RichNode left, RichNode right);

  inline
  void rebind(VM vm, RichNode left, RichNode right);

  inline
  void undoBindings(VM vm);

  inline
  void doCapture(VM vm, RichNode value, RichNode capture);

  inline
  void doConjunction(VM vm, RichNode value, RichNode conjunction);

  inline
  OpResult doOpenRecord(VM vm, RichNode value, RichNode pattern);

  VM vm;
  Kind kind;

  WalkStack stack;
  RebindTrail rebindTrail;
  SuspendTrail suspendTrail;

  StaticArray<UnstableNode> captures;
};

/////////////////
// Entry point //
/////////////////

OpResult fullUnify(VM vm, RichNode left, RichNode right) {
  StructuralDualWalk walk(vm, StructuralDualWalk::wkUnify);
  return walk.run(left, right);
}

OpResult fullEquals(VM vm, RichNode left, RichNode right, bool& result) {
  StructuralDualWalk walk(vm, StructuralDualWalk::wkEquals);
  return walk.run(left, right).mapProceedFailToTrueFalse(result);
}

OpResult fullPatternMatch(VM vm, RichNode value, RichNode pattern,
                          StaticArray<UnstableNode> captures, bool& result) {
  StructuralDualWalk walk(vm, StructuralDualWalk::wkPatternMatch, captures);
  return walk.run(value, pattern).mapProceedFailToTrueFalse(result);
}

////////////////////
// The real thing //
////////////////////

OpResult StructuralDualWalk::run(RichNode left, RichNode right) {
  VM vm = this->vm;

  while (true) {
    // Process the pair
    OpResult pairResult = processPair(vm, left, right);

    switch (pairResult.kind()) {
      case OpResult::orFail:
      case OpResult::orRaise: {
        stack.clear(vm);
        suspendTrail.clear(vm);
        undoBindings(vm);
        return pairResult;
      }

      case OpResult::orWaitBefore:
      case OpResult::orWaitQuietBefore: {
        // TODO Do we need to actually support the *quiet* here?
        suspendTrail.push_back_new(vm, left.getStableRef(vm),
                                   right.getStableRef(vm));
        break;
      }

      case OpResult::orProceed: {
        // nothing to do
      }
    }

    // Finished?
    if (stack.empty())
      break;

    // Pop next pair
    left = *stack.front().left;
    right = *stack.front().right;

    // Go to next item
    stack.remove_front(vm);
  }

  // Do we need to suspend on something?
  if (!suspendTrail.empty()) {
    // Undo temporary bindings

    undoBindings(vm);

    // Create the control variable

    UnstableNode unstableControlVar = Variable::build(vm);
    RichNode controlVar = unstableControlVar;
    controlVar.ensureStable(vm);

    // Reduce the remaining unifications
    size_t count = suspendTrail.size();

    if (count == 1) {
      left = *suspendTrail.front().left;
      right = *suspendTrail.front().right;

      if (left.isTransient())
        DataflowVariable(left).addToSuspendList(vm, controlVar);

      if (right.isTransient())
        DataflowVariable(right).addToSuspendList(vm, controlVar);
    } else {
      UnstableNode label = Atom::build(vm, vm->coreatoms.pipe);

      UnstableNode unstableLeft = Tuple::build(vm, count, label);
      UnstableNode unstableRight = Tuple::build(vm, count, label);

      auto leftTuple = RichNode(unstableLeft).as<Tuple>();
      auto rightTuple = RichNode(unstableRight).as<Tuple>();

      size_t i = 0;
      for (auto iter = suspendTrail.begin();
           iter != suspendTrail.end(); i++, ++iter) {
        UnstableNode leftTemp(vm, *iter->left);
        leftTuple.initElement(vm, i, leftTemp);

        RichNode richLeftTemp = leftTemp;
        if (richLeftTemp.isTransient())
          DataflowVariable(richLeftTemp).addToSuspendList(vm, controlVar);

        UnstableNode rightTemp(vm, *iter->right);
        rightTuple.initElement(vm, i, rightTemp);

        RichNode richRightTemp = rightTemp;
        if (richRightTemp.isTransient())
          DataflowVariable(richRightTemp).addToSuspendList(vm, controlVar);
      }
    }

    suspendTrail.clear(vm);

    // TODO Replace initial operands by unstableLeft and unstableRight

    return OpResult::waitFor(vm, controlVar);
  }

  /* No need to undo temporary bindings here, even if we are in wkEquals mode.
   * In fact, we should not undo them in that case, as that compactifies
   * the store, and speeds up subsequent tests and/or unifications.
   *
   * However, the above is *wrong* when in a subspace, because of speculative
   * bindings.
   *
   * The above would also be *wrong* when in wkPatternMatch mode. But in that
   * mode we do not perform temporary bindings in the first place.
   */
  if (!vm->isOnTopLevel())
    undoBindings(vm);

  return OpResult::proceed();
}

OpResult StructuralDualWalk::processPair(VM vm, RichNode left,
                                         RichNode right) {
  // Identical nodes
  if (left.isSameNode(right))
    return OpResult::proceed();

  auto leftType = left.type();
  auto rightType = right.type();

  StructuralBehavior leftBehavior = leftType.getStructuralBehavior();
  StructuralBehavior rightBehavior = rightType.getStructuralBehavior();

  // Handle captures
  if (kind == wkPatternMatch) {
    if (rightType == PatMatCapture::type()) {
      doCapture(vm, left, right);
      return OpResult::proceed();
    } else if (rightType == PatMatConjunction::type()) {
      doConjunction(vm, left, right);
      return OpResult::proceed();
    } else if (rightType == PatMatOpenRecord::type()) {
      return doOpenRecord(vm, left, right);
    }
  }

  // One of them is a variable
  switch (kind) {
    case wkUnify: {
      if (leftBehavior == sbVariable) {
        if (rightBehavior == sbVariable) {
          if (leftType.getBindingPriority() > rightType.getBindingPriority())
            return DataflowVariable(left).bind(vm, right);
          else
            return DataflowVariable(right).bind(vm, left);
        } else {
          return DataflowVariable(left).bind(vm, right);
        }
      } else if (rightBehavior == sbVariable) {
        return DataflowVariable(right).bind(vm, left);
      }

      break;
    }

    case wkEquals:
    case wkPatternMatch: {
      if (leftBehavior == sbVariable) {
        assert(leftType.isTransient());
        return OpResult::waitFor(vm, left);
      } else if (rightBehavior == sbVariable) {
        assert(rightType.isTransient());
        return OpResult::waitFor(vm, right);
      }

      break;
    }
  }

  // If we reach this, both left and right are non-var
  if (leftType != rightType)
    return OpResult::fail();

  switch (leftBehavior) {
    case sbValue: {
      bool success = ValueEquatable(left).equals(vm, right);
      return success ? OpResult::proceed() : OpResult::fail();
    }

    case sbStructural: {
      bool success = StructuralEquatable(left).equals(vm, right, stack);
      if (success) {
        if (kind != wkPatternMatch)
          rebind(vm, left, right);
        return OpResult::proceed();
      } else {
        return OpResult::fail();
      }
    }

    case sbTokenEq: {
      assert(!left.isSameNode(right)); // this was tested earlier
      return OpResult::fail();
    }

    case sbVariable: {
      assert(false);
      return OpResult::fail();
    }
  }

  // We should not reach this point
  assert(false);
  return OpResult::proceed();
}

void StructuralDualWalk::rebind(VM vm, RichNode left, RichNode right) {
  rebindTrail.push_back(vm, left.makeBackup());
  left.reinit(vm, right);
}

void StructuralDualWalk::undoBindings(VM vm) {
  while (!rebindTrail.empty()) {
    rebindTrail.front().restore();
    rebindTrail.remove_front(vm);
  }
}

void StructuralDualWalk::doCapture(VM vm, RichNode value, RichNode capture) {
  nativeint index = capture.as<PatMatCapture>().index();

  if (index >= 0)
    captures[(size_t) index].copy(vm, value);
}

void StructuralDualWalk::doConjunction(VM vm, RichNode value,
                                       RichNode conjunction) {
  auto conj = conjunction.as<PatMatConjunction>();
  StableNode* stableValue = value.getStableRef(vm);

  for (size_t i = conj.getCount(); i > 0; i--)
    stack.push(vm, stableValue, conj.getElement(i-1));
}

OpResult StructuralDualWalk::doOpenRecord(VM vm, RichNode value,
                                          RichNode pattern) {
  bool boolResult = false;
  auto pat = pattern.as<PatMatOpenRecord>();
  auto arity = RichNode(*pat.getArity()).as<Arity>();

  // Check that the value is a record

  MOZART_CHECK_OPRESULT(RecordLike(value).isRecord(vm, boolResult));
  if (!boolResult)
    return OpResult::fail();

  // Check that the labels match

  UnstableNode recordLabel;
  MOZART_CHECK_OPRESULT(RecordLike(value).label(vm, recordLabel));

  MOZART_CHECK_OPRESULT(equals(vm, *arity.getLabel(), recordLabel, boolResult));
  if (!boolResult)
    return OpResult::fail();

  // Now iterate over the features of the pattern

  for (size_t i = 0; i < arity.getArraySize(); i++) {
    RichNode feature = *arity.getElement(i);

    MOZART_CHECK_OPRESULT(Dottable(value).hasFeature(vm, feature, boolResult));
    if (!boolResult)
      return OpResult::fail();

    UnstableNode lhsValue;
    MOZART_CHECK_OPRESULT(Dottable(value).dot(vm, feature, lhsValue));
    StableNode* rhsValue = pat.getElement(i);

    stack.push(vm, RichNode(lhsValue).getStableRef(vm), rhsValue);
  }

  return OpResult::proceed();
}

}
