#include "mozartcore.hh"
#include "coreinterfaces.hh"
#include "corebuiltins.hh"

#include <gtest/gtest.h>

class SmallIntTest : public ::testing::Test {
protected:
  SmallIntTest() : virtualMachine(nullptr, nullptr), vm(&virtualMachine) {}

  virtual void SetUp() {
  }

  virtual void TearDown() {
  }

  void EXPECT_EQ_INT(nativeint expected, Node& actual) {
    IntegerValue intValue = actual;
    bool result = false;
    intValue.equalsInteger(vm, expected, &result);
    EXPECT_TRUE(result);
  }

  // The VM
  VirtualMachine virtualMachine;
  VM vm;
};


TEST_F(SmallIntTest, Build) {
  for (nativeint i = -5; i <= 5; i++) {
    UnstableNode node;
    node.make<SmallInt>(vm, i);

    EXPECT_EQ(SmallInt::type(), node.node.type);
    EXPECT_EQ_INT(i, node.node);
  }
}


TEST_F(SmallIntTest, Add) {
  UnstableNode leftNode, rightNode, resultNode;

  for (nativeint left = -5; left <= 5; left++) {
    leftNode.make<SmallInt>(vm, left);

    for (nativeint right = -5; right <= 5; right++) {
      rightNode.make<SmallInt>(vm, right);

      Numeric leftNumeric = leftNode.node;
      leftNumeric.add(vm, &rightNode, &resultNode);

      EXPECT_EQ_INT(left+right, resultNode.node);
    }
  }
}


int main(int argc, char **argv) {
  ::testing::InitGoogleTest(&argc, argv);
  return RUN_ALL_TESTS();
}
