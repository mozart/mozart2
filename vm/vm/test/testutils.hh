#ifndef __TESTUTILS_HH
#define __TESTUTILS_HH

#include "mozart.hh"
#include <gtest/gtest.h>

std::unique_ptr<mozart::VirtualMachineEnvironment> makeTestEnvironment();

namespace mozart {

class MozartTest : public ::testing::Test {
protected:
  MozartTest() : environment(makeTestEnvironment()),
                 virtualMachine(*environment),
                 vm(&virtualMachine) {}

  virtual void SetUp() {
  }

  virtual void TearDown() {
  }

  // The VM
  std::unique_ptr<VirtualMachineEnvironment> environment;
  VirtualMachine virtualMachine;
  VM vm;

  //--- Some common tests ----------------------------------------------------

  /**
   * Expect that the node has the type of the given template parameter. Use it
   * like::
   *
   *     if (EXPECT_IS<SmallInt>(node)) {
   *        node.as<SmallInt>().etc();
   *     }
   */
  template <class Type>
  static bool EXPECT_IS(RichNode actual) {
    EXPECT_EQ(Type::type(), actual.type());
    return Type::type() == actual.type();
  }

  /**
   * Expect that a node is an atom and the content is the given
   * null-terminated string.
   */
  bool EXPECT_EQ_ATOM(LString<nchar> expected, RichNode actual) const {
    if (!EXPECT_IS<Atom>(actual))
      return false;

    const AtomImpl* impl = actual.as<Atom>().value();
    LString<nchar> actualString(impl->contents(), impl->length());
    EXPECT_EQ(expected, actualString);
    return expected == actualString;
  }

  /**
   * Expect that a node is a small integer and the content is the given
   * native integer.
   */
  static bool EXPECT_EQ_INT(nativeint expected, RichNode actual) {
    if (!EXPECT_IS<SmallInt>(actual))
      return false;

    nativeint actualValue = actual.as<SmallInt>().value();
    EXPECT_EQ(expected, actualValue);
    return expected == actualValue;
  }

  /**
   * Expect that a node is a float and the content is the given value.
   */
  static void EXPECT_EQ_FLOAT(double expected, RichNode actual) {
    if (!EXPECT_IS<Float>(actual))
      return;

    double actualValue = actual.as<Float>().value();
    EXPECT_DOUBLE_EQ(expected, actualValue);
  }

  /**
   * Expect that a method returns ``OpResult::proceed()``.
   */
  static bool EXPECT_PROCEED(OpResult result) {
    bool isProceed = result.isProceed();
    EXPECT_TRUE(isProceed);
    return isProceed;
  }

  /**
   * Expect that a method returns ``OpResult::raise()``, and the label of the
   * exception record is an atom of the null-terminated Unicode string.
   */
  bool EXPECT_RAISE(const nchar* label, OpResult result) const;
};

std::ostream& operator<<(std::ostream& out, LString<nchar> input);

}

#endif
