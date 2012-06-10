#include "mozart.hh"

#include <gtest/gtest.h>

#include "testutils.hh"

using namespace mozart;

class SmallIntTest : public MozartTest {};

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
