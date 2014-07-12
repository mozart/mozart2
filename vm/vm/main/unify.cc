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
    kind(kind), captures(captures) {}

  bool run(VM vm, RichNode left, RichNode right);
private:
  inline
  bool processPair(VM vm, RichNode left, RichNode right);

  inline
  void rebind(VM vm, RichNode left, RichNode right);

  inline
  void cleanupOnFailure(VM vm);

  inline
  void undoBindings(VM vm);

  inline
  void doConjunction(VM vm, RichNode value, RichNode conjunction);

  inline
  bool doOpenRecord(VM vm, RichNode value, RichNode pattern);

  Kind kind;

  WalkStack stack;
  RebindTrail rebindTrail;
  SuspendTrail suspendTrail;

  StaticArray<UnstableNode> captures;
};

/////////////////
// Entry point //
/////////////////

void fullUnify(VM vm, RichNode left, RichNode right) {
  StructuralDualWalk walk(vm, StructuralDualWalk::wkUnify);
  if (!walk.run(vm, left, right)) {
    UnstableNode info = buildList(vm, buildTuple(vm, "eq", left, right));
    fail(vm, info);
  }
}

bool fullEquals(VM vm, RichNode left, RichNode right) {
  StructuralDualWalk walk(vm, StructuralDualWalk::wkEquals);
  return walk.run(vm, left, right);
}

bool fullPatternMatch(VM vm, RichNode value, RichNode pattern,
                      StaticArray<UnstableNode> captures) {
  StructuralDualWalk walk(vm, StructuralDualWalk::wkPatternMatch, captures);
  return walk.run(vm, value, pattern);
}

////////////////////////////
// Quick pattern matching //
////////////////////////////

static void doCapture(VM vm, RichNode value, RichNode capture,
                      StaticArray<UnstableNode> captures) {
  nativeint index = capture.as<PatMatCapture>().index();
  if (index >= 0)
    captures[(size_t) index].copy(vm, value);
}

// This function identifies some common patterns and performs match before
// needing to do full stack walking.
PatternMatchResult quickPatternMatch(VM vm, RichNode value, RichNode pattern,
                                     StaticArray<UnstableNode> captures) {
  if (value.isSameNode(pattern))
    return PatternMatchResult::succeed;

  auto valueType = value.type();
  auto patternType = pattern.type();

  // Bind a bare PatMatCapture directly.
  if (patternType == PatMatCapture::type()) {
    doCapture(vm, value, pattern, captures);
    return PatternMatchResult::succeed;
  }

  auto valueBehavior = valueType.getStructuralBehavior();
  auto patternBehavior = patternType.getStructuralBehavior();

  // The following are taken from `equals()`...
  if (valueBehavior == sbVariable || patternBehavior == sbVariable)
    return PatternMatchResult::unknown;

  // Let full pattern matching work with more complex pat-mat objects.
  if (patternType == PatMatConjunction::type())
    return PatternMatchResult::unknown;
  if (patternType == PatMatOpenRecord::type())
    return PatternMatchResult::unknown;

  // At this point, we can safely short-circruit anything with different shape.
  if (valueType != patternType)
    return PatternMatchResult::failed;

  switch (valueBehavior) {
    // These two are the same as `equals()`.
    case sbValue:
      if (ValueEquatable(value).equals(vm, pattern))
        return PatternMatchResult::succeed;
      else
        return PatternMatchResult::failed;

    case sbTokenEq:
      return PatternMatchResult::failed;

    case sbStructural: {
      // Majority of pattern matches are tuples like r(X Y Z), or cons like H|T
      if (valueType == Tuple::type()) {

        // For tuples, first ensure labels and widths are the same.
        auto valueTuple = value.as<Tuple>();
        auto patternTuple = pattern.as<Tuple>();
        auto label = valueTuple.label(vm);
        auto width = valueTuple.width(vm);
        if (!patternTuple.testTuple(vm, label, width))
          return PatternMatchResult::failed;

        // Then check that the patterns only contain PatMatCaptures, otherwise
        // we fallback to fullPatternMatch().
        auto patternsArray = patternTuple.getElementsArray();
        for (size_t i = 0; i < width; ++ i) {
          if (!RichNode(patternsArray[i]).is<PatMatCapture>())
            return PatternMatchResult::unknown;
        }

        // Finally perform the capture and return.
        auto valuesArray = valueTuple.getElementsArray();
        for (size_t i = 0; i < width; ++ i) {
          doCapture(vm, valuesArray[i], patternsArray[i], captures);
        }
        return PatternMatchResult::succeed;

      } else if (valueType == Cons::type()) {

        // Cons matching usually comes in these forms:
        //  1. H|T
        //  2. X#Y|T
        //  3. a|T
        // So here we ensure the tail is PatMatCapture, and the head is a value
        // type, PatMatCapture (also a value type) or a tuple (but not cons).
        // Then we perform capturing on the head and tail respectively.

        auto patternsArray = pattern.as<Cons>().getElementsArray();
        auto valuesArray = value.as<Cons>().getElementsArray();

        if (!RichNode(patternsArray[1]).is<PatMatCapture>())
          return PatternMatchResult::unknown;

        RichNode patternHead(patternsArray[0]);
        auto patternHeadType = patternHead.type();
        if (patternHeadType != Tuple::type() && patternHeadType.getStructuralBehavior() != sbValue)
          return PatternMatchResult::unknown;

        // Since head is never Cons, the recursion depth will be limited to 2.
        auto res = quickPatternMatch(vm, valuesArray[0], patternHead, captures);
        if (res == PatternMatchResult::succeed) {
          // Perform capture only if we are sure the heads match.
          doCapture(vm, valuesArray[1], patternsArray[1], captures);
        }
        return res;

      } else {

        // We don't care about more complex cases.
        return PatternMatchResult::unknown;

      }
    }

    default:
      return PatternMatchResult::unknown;
  }
}

////////////////////
// The real thing //
////////////////////

bool StructuralDualWalk::run(VM vm, RichNode left, RichNode right) {
  MOZART_TRY(vm) {
    /* We put the while inside the try-catch
     * Avoids to install and deinstall the handler on every pair
     */
    while (true) {
      // Process the pair
      if (!processPair(vm, left, right)) {
        cleanupOnFailure(vm);
        MOZART_RETURN_IN_TRY(vm, false);
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
  } MOZART_CATCH(vm, kind, node) {
    switch (kind) {
      case ExceptionKind::ekWaitBefore: {
        // TODO Do we need to actually support the *quiet* here?
        if (!RichNode(*node).is<FailedValue>()) {
          suspendTrail.push_back_new(vm, left.getStableRef(vm),
                                     right.getStableRef(vm));

          // We must process the next pair nevertheless -> tail call

          // Finished?
          if (!stack.empty()) {
            // Pop next pair
            left = *stack.front().left;
            right = *stack.front().right;

            // Go to next item
            stack.remove_front(vm);

            return run(vm, left, right);
          }
        } else {
          cleanupOnFailure(vm);
          MOZART_RETHROW(vm);
        }

        break;
      }

      default: {
        cleanupOnFailure(vm);
        MOZART_RETHROW(vm);
      }
    }
  } MOZART_ENDTRY(vm);

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

      if (left.isTransient()) {
        DataflowVariable(left).markNeeded(vm);
        DataflowVariable(left).addToSuspendList(vm, controlVar);
      }

      if (right.isTransient()) {
        DataflowVariable(right).markNeeded(vm);
        DataflowVariable(right).addToSuspendList(vm, controlVar);
      }
    } else {
      UnstableNode label = Atom::build(vm, vm->coreatoms.pipe);

      UnstableNode unstableLeft = Tuple::build(vm, count, label);
      UnstableNode unstableRight = Tuple::build(vm, count, label);

      auto leftElements = RichNode(unstableLeft).as<Tuple>().getElementsArray();
      auto rightElements = RichNode(unstableRight).as<Tuple>().getElementsArray();

      size_t i = 0;
      for (auto iter = suspendTrail.begin();
           iter != suspendTrail.end(); i++, ++iter) {
        UnstableNode leftTemp(vm, *iter->left);
        leftElements[i].init(vm, leftTemp);

        RichNode richLeftTemp = leftTemp;
        if (richLeftTemp.isTransient()) {
          DataflowVariable(richLeftTemp).markNeeded(vm);
          DataflowVariable(richLeftTemp).addToSuspendList(vm, controlVar);
        }

        UnstableNode rightTemp(vm, *iter->right);
        rightElements[i].init(vm, rightTemp);

        RichNode richRightTemp = rightTemp;
        if (richRightTemp.isTransient()) {
          DataflowVariable(richRightTemp).markNeeded(vm);
          DataflowVariable(richRightTemp).addToSuspendList(vm, controlVar);
        }
      }
    }

    suspendTrail.clear(vm);

    // TODO Replace initial operands by unstableLeft and unstableRight

    waitFor(vm, controlVar);
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

  return true;
}

bool StructuralDualWalk::processPair(VM vm, RichNode left, RichNode right) {
  // Identical nodes
  if (left.isSameNode(right))
    return true;

  auto leftType = left.type();
  auto rightType = right.type();

  StructuralBehavior leftBehavior = leftType.getStructuralBehavior();
  StructuralBehavior rightBehavior = rightType.getStructuralBehavior();

  // Handle captures
  if (kind == wkPatternMatch) {
    if (rightType == PatMatCapture::type()) {
      doCapture(vm, left, right, captures);
      return true;
    } else if (rightType == PatMatConjunction::type()) {
      doConjunction(vm, left, right);
      return true;
    } else if (rightType == PatMatOpenRecord::type()) {
      return doOpenRecord(vm, left, right);
    }
  }

  // One of them is a variable
  switch (kind) {
    case wkUnify: {
      if (leftBehavior == sbVariable) {
        if (rightBehavior == sbVariable) {
          if (leftType.getBindingPriority() > rightType.getBindingPriority()) {
            DataflowVariable(left).bind(vm, right);
            return true;
          } else {
            DataflowVariable(right).bind(vm, left);
            return true;
          }
        } else {
          DataflowVariable(left).bind(vm, right);
          return true;
        }
      } else if (rightBehavior == sbVariable) {
        DataflowVariable(right).bind(vm, left);
        return true;
      }

      break;
    }

    case wkEquals:
    case wkPatternMatch: {
      if (leftBehavior == sbVariable) {
        assert(leftType.isTransient());
        waitFor(vm, left);
      } else if (rightBehavior == sbVariable) {
        assert(rightType.isTransient());
        waitFor(vm, right);
      }

      break;
    }
  }

  // If we reach this, both left and right are non-var
  if (leftType != rightType)
    return false;

  switch (leftBehavior) {
    case sbValue: {
      return ValueEquatable(left).equals(vm, right);
    }

    case sbStructural: {
      bool success = StructuralEquatable(left).equals(vm, right, stack);
      if (success) {
        if (kind != wkPatternMatch)
          rebind(vm, left, right);
        return true;
      } else {
        return false;
      }
    }

    case sbTokenEq: {
      assert(!left.isSameNode(right)); // this was tested earlier
      return false;
    }

    default: { // including sbVariable
      assert(false);
      return false;
    }
  }
}

void StructuralDualWalk::rebind(VM vm, RichNode left, RichNode right) {
  rebindTrail.push_back(vm, left.makeBackup());
  left.reinit(vm, right);
}

void StructuralDualWalk::cleanupOnFailure(VM vm) {
  stack.clear(vm);
  suspendTrail.clear(vm);
  undoBindings(vm);
}

void StructuralDualWalk::undoBindings(VM vm) {
  while (!rebindTrail.empty()) {
    rebindTrail.front().restore();
    rebindTrail.remove_front(vm);
  }
}

void StructuralDualWalk::doConjunction(VM vm, RichNode value,
                                       RichNode conjunction) {
  auto conj = conjunction.as<PatMatConjunction>();
  StableNode* stableValue = value.getStableRef(vm);

  for (size_t i = conj.getCount(); i > 0; i--)
    stack.push(vm, stableValue, conj.getElement(i-1));
}

bool StructuralDualWalk::doOpenRecord(VM vm, RichNode value,
                                      RichNode pattern) {
  auto pat = pattern.as<PatMatOpenRecord>();
  auto arity = RichNode(*pat.getArity()).as<Arity>();

  // Check that the value is a record

  if (!RecordLike(value).isRecord(vm))
    return false;

  // Check that the labels match

  auto label = RecordLike(value).label(vm);
  if (!equals(vm, *arity.getLabel(), label))
    return false;

  // Now iterate over the features of the pattern

  for (size_t i = 0; i < arity.getArraySize(); i++) {
    RichNode feature = *arity.getElement(i);

    if (!Dottable(value).hasFeature(vm, feature))
      return false;

    auto lhsValue = Dottable(value).dot(vm, feature);
    StableNode* rhsValue = pat.getElement(i);

    stack.push(vm, RichNode(lhsValue).getStableRef(vm), rhsValue);
  }

  return true;
}

}
