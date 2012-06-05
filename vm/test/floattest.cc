#include "mozart.hh"

#include <gtest/gtest.h>

#include "testutils.hh"

using namespace mozart;

class FloatTest : public ::testing::Test {
protected:
  FloatTest() : virtualMachine(makeTestEnvironment()), vm(&virtualMachine) {}

  virtual void SetUp() {
  }

  virtual void TearDown() {
  }

  void EXPECT_EQ_FLOAT(double expected, RichNode actual) {
    EXPECT_EQ(Float::type(), actual.type());
    if (actual.type() == Float::type())
      EXPECT_DOUBLE_EQ(expected, actual.as<Float>().value());
  }

  // The VM
  VirtualMachine virtualMachine;
  VM vm;
};


TEST_F(FloatTest, Build) {
  for (double i = -5; i <= 5; i++) {
    UnstableNode node = Float::build(vm, i);
    EXPECT_EQ_FLOAT(i, node);
  }
}


TEST_F(FloatTest, Add) {
  for (double left = -5; left <= 5; left++) {
    UnstableNode leftNode = Float::build(vm, left);

    for (double right = -5; right <= 5; right++) {
      UnstableNode rightNode = Float::build(vm, right);

      UnstableNode resultNode;
      Numeric(leftNode).add(vm, rightNode, resultNode);

      EXPECT_EQ_FLOAT(left + right, resultNode);
    }
  }
}


TEST_F(FloatTest, Subtract) {
  for (double left = -5; left <= 5; left++) {
    UnstableNode leftNode = Float::build(vm, left);

    for (double right = -5; right <= 5; right++) {
      UnstableNode rightNode = Float::build(vm, right);

      UnstableNode resultNode;
      Numeric(leftNode).subtract(vm, rightNode, resultNode);

      EXPECT_EQ_FLOAT(left - right, resultNode);
    }
  }
}


TEST_F(FloatTest, Multiply) {
  for (double left = -5; left <= 5; left++) {
    UnstableNode leftNode = Float::build(vm, left);

    for (double right = -5; right <= 5; right++) {
      UnstableNode rightNode = Float::build(vm, right);

      UnstableNode resultNode;
      Numeric(leftNode).multiply(vm, rightNode, resultNode);

      EXPECT_EQ_FLOAT(left * right, resultNode);
    }
  }
}

TEST_F(FloatTest, Divide) {
  for (double left = -5; left <= 5; left++) {
    UnstableNode leftNode = Float::build(vm, left);

    for (double right = -5; right <= 5; right++) {
      if (right == 0)
        continue;

      UnstableNode rightNode = Float::build(vm, right);

      UnstableNode resultNode;
      Numeric(leftNode).divide(vm, rightNode, resultNode);

      EXPECT_EQ_FLOAT(left / right, resultNode);
    }
  }
}
