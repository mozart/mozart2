#include "mozart.hh"

#include <gtest/gtest.h>

using namespace mozart;

class FloatTest : public ::testing::Test {
protected:
  FloatTest() : virtualMachine(nullptr, nullptr), vm(&virtualMachine) {}

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
    UnstableNode node;
    node.make<Float>(vm, i);

    EXPECT_EQ_FLOAT(i, node);
  }
}


TEST_F(FloatTest, Add) {
  UnstableNode leftNode, rightNode, resultNode;

  for (double left = -5; left <= 5; left++) {
    leftNode.make<Float>(vm, left);

    for (double right = -5; right <= 5; right++) {
      rightNode.make<Float>(vm, right);

      Numeric leftNumeric = leftNode;
      leftNumeric.add(vm, &rightNode, &resultNode);

      EXPECT_EQ_FLOAT(left + right, resultNode);
    }
  }
}


TEST_F(FloatTest, Subtract) {
  UnstableNode leftNode, rightNode, resultNode;

  for (double left = -5; left <= 5; left++) {
    leftNode.make<Float>(vm, left);

    for (double right = -5; right <= 5; right++) {
      rightNode.make<Float>(vm, right);

      Numeric leftNumeric = leftNode;
      leftNumeric.subtract(vm, &rightNode, &resultNode);

      EXPECT_EQ_FLOAT(left - right, resultNode);
    }
  }
}


TEST_F(FloatTest, Multiply) {
  UnstableNode leftNode, rightNode, resultNode;

  for (double left = -5; left <= 5; left++) {
    leftNode.make<Float>(vm, left);

    for (double right = -5; right <= 5; right++) {
      rightNode.make<Float>(vm, right);

      Numeric leftNumeric = leftNode;
      leftNumeric.multiply(vm, &rightNode, &resultNode);

      EXPECT_EQ_FLOAT(left * right, resultNode);
    }
  }
}

TEST_F(FloatTest, Divide) {
  UnstableNode leftNode, rightNode, resultNode;

  for (double left = -5; left <= 5; left++) {
    leftNode.make<Float>(vm, left);

    for (int rightInt = -5; rightInt <= 5; rightInt++) {
      if (rightInt != 0) {
        double right = rightInt;
        rightNode.make<Float>(vm, right);

        Numeric leftNumeric = leftNode;
        leftNumeric.divide(vm, &rightNode, &resultNode);

        EXPECT_EQ_FLOAT(left / right, resultNode);
      }
    }
  }
}
