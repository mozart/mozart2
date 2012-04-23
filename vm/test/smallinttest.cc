#include "mozart.hh"

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
  for (nativeint left = -5; left <= 5; left++) {
    UnstableNode leftNode = SmallInt::build(vm, left);

    for (nativeint right = -5; right <= 5; right++) {
      UnstableNode rightNode = SmallInt::build(vm, right);

      UnstableNode resultNode;
      Numeric(leftNode).add(vm, rightNode, resultNode);

      EXPECT_EQ_INT(left + right, resultNode);
    }
  }
}


TEST_F(SmallIntTest, Subtract) {
  for (nativeint left = -5; left <= 5; left++) {
    UnstableNode leftNode = SmallInt::build(vm, left);

    for (nativeint right = -5; right <= 5; right++) {
      UnstableNode rightNode = SmallInt::build(vm, right);

      UnstableNode resultNode;
      Numeric(leftNode).subtract(vm, rightNode, resultNode);

      EXPECT_EQ_INT(left - right, resultNode);
    }
  }
}


TEST_F(SmallIntTest, Multiply) {
  for (nativeint left = -5; left <= 5; left++) {
    UnstableNode leftNode = SmallInt::build(vm, left);

    for (nativeint right = -5; right <= 5; right++) {
      UnstableNode rightNode = SmallInt::build(vm, right);

      UnstableNode resultNode;
      Numeric(leftNode).multiply(vm, rightNode, resultNode);

      EXPECT_EQ_INT(left * right, resultNode);
    }
  }
}

TEST_F(SmallIntTest, Div) {
  for (nativeint left = -5; left <= 5; left++) {
    UnstableNode leftNode = SmallInt::build(vm, left);

    for (nativeint right = -5; right <= 5; right++) {
      if (right == 0)
        continue;

      UnstableNode rightNode = SmallInt::build(vm, right);

      UnstableNode resultNode;
      Numeric(leftNode).div(vm, rightNode, resultNode);

      EXPECT_EQ_INT(left / right, resultNode);
    }
  }
}

TEST_F(SmallIntTest, Mod) {
  for (nativeint left = -5; left <= 5; left++) {
    UnstableNode leftNode = SmallInt::build(vm, left);

    for (nativeint right = -5; right <= 5; right++) {
      if (right == 0)
        continue;

      UnstableNode rightNode = SmallInt::build(vm, right);

      UnstableNode resultNode;
      Numeric(leftNode).mod(vm, rightNode, resultNode);

      EXPECT_EQ_INT(left % right, resultNode);
    }
  }
}
