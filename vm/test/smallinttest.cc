#include "mozartcore.hh"
#include "coreinterfaces.hh"
#include "corebuiltins.hh"

#include <gtest/gtest.h>

using namespace mozart;

class SmallIntTest : public ::testing::Test {
protected:
  SmallIntTest() : virtualMachine(nullptr, nullptr), vm(&virtualMachine) {}

  virtual void SetUp() {
  }

  virtual void TearDown() {
  }

  void EXPECT_EQ_INT(nativeint expected, RichNode actual) {
    EXPECT_EQ(SmallInt::type(), actual.type());
    if (actual.type() == SmallInt::type())
      EXPECT_EQ(expected, actual.as<SmallInt>().value());
  }

  // The VM
  VirtualMachine virtualMachine;
  VM vm;
};


TEST_F(SmallIntTest, Build) {
  for (nativeint i = -5; i <= 5; i++) {
    UnstableNode node;
    node.make<SmallInt>(vm, i);

    EXPECT_EQ_INT(i, node);
  }
}


TEST_F(SmallIntTest, Add) {
  UnstableNode leftNode, rightNode, resultNode;

  for (nativeint left = -5; left <= 5; left++) {
    leftNode.make<SmallInt>(vm, left);

    for (nativeint right = -5; right <= 5; right++) {
      rightNode.make<SmallInt>(vm, right);

      Numeric leftNumeric = leftNode;
      leftNumeric.add(vm, &rightNode, &resultNode);

      EXPECT_EQ_INT(left+right, resultNode);
    }
  }
}


TEST_F(SmallIntTest, Subtract) {
  UnstableNode leftNode, rightNode, resultNode;

  for (nativeint left = -5; left <= 5; left++) {
    leftNode.make<SmallInt>(vm, left);

    for (nativeint right = -5; right <= 5; right++) {
      rightNode.make<SmallInt>(vm, right);

      Numeric leftNumeric = leftNode;
      leftNumeric.subtract(vm, &rightNode, &resultNode);

      EXPECT_EQ_INT(left-right, resultNode);
    }
  }
}


TEST_F(SmallIntTest, Multiply) {
  UnstableNode leftNode, rightNode, resultNode;

  for (nativeint left = -5; left <= 5; left++) {
    leftNode.make<SmallInt>(vm, left);

    for (nativeint right = -5; right <= 5; right++) {
      rightNode.make<SmallInt>(vm, right);

      Numeric leftNumeric = leftNode;
      leftNumeric.multiply(vm, &rightNode, &resultNode);

      EXPECT_EQ_INT((left * right), resultNode);
    }
  }
}

TEST_F(SmallIntTest, Div) {
  UnstableNode leftNode, rightNode, resultNode;

  for (nativeint left = -5; left <= 5; left++) {
    leftNode.make<SmallInt>(vm, left);

    for (nativeint right = -5; right <= 5; right++) {
      if (right == 0) {
        continue;
      } else {
        rightNode.make<SmallInt>(vm, right);

        Numeric leftNumeric = leftNode;
        leftNumeric.div(vm, &rightNode, &resultNode);

        EXPECT_EQ_INT(left / right, resultNode);
      }
    }
  }
}

TEST_F(SmallIntTest, Mod) {
  UnstableNode leftNode, rightNode, resultNode;

  for (nativeint left = -5; left <= 5; left++) {
    leftNode.make<SmallInt>(vm, left);

    for (nativeint right = -10; right <= 10; right++) {
      if (right == 0) {
        continue;
      } else {
        rightNode.make<SmallInt>(vm, right);

        Numeric leftNumeric = leftNode;
        leftNumeric.mod(vm, &rightNode, &resultNode);

        EXPECT_EQ_INT(left % right, resultNode);
      }
    }
  }
}
