#ifndef __TESTUTILS_HH
#define __TESTUTILS_HH

#include "mozart.hh"
#include <gtest/gtest.h>

std::unique_ptr<mozart::VirtualMachineEnvironment> makeTestEnvironment();

namespace mozart {

class MozartTest : public ::testing::Test {
protected:
  MozartTest() : environment(makeTestEnvironment()),
                 virtualMachine(*environment, 10 * MegaBytes),
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
   * Expect that the repr() of a node is the given string
   */
  bool EXPECT_REPR_EQ(const BaseLString<char>& expected, RichNode node) const {
    std::stringstream ss;
    ss << repr(vm, node);
    auto str = ss.str();
    auto actual = makeLString(str.c_str(), str.length());
    EXPECT_EQ(expected, actual);
    return expected == actual;
  }

  /**
   * Expect that the repr() of a node is the given string
   */
  bool EXPECT_REPR_EQ(const BaseLString<char>& expected,
                      UnstableNode&& node) const {
    return EXPECT_REPR_EQ(expected, RichNode(node));
  }

  /**
   * Expect that a node is an atom and the content is the given
   * null-terminated string.
   */
  bool EXPECT_EQ_ATOM(const BaseLString<char>& expected,
                      RichNode actual) const {
    if (!EXPECT_IS<Atom>(actual))
      return false;

    atom_t impl = actual.as<Atom>().value();
    auto actualString = makeLString(impl.contents(), impl.length());
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
   * Expect that a node is a string and the content is the given
   * null-terminated string.
   */
  static bool EXPECT_EQ_STRING(const BaseLString<char>& expected,
                               RichNode actual) {
    if (!EXPECT_IS<String>(actual))
      return false;

    auto actualString = actual.as<String>().value();
    EXPECT_EQ(expected, actualString);
    return expected == actualString;
  }

  /**
   * Expect that a node is a string and the content is the given
   * null-terminated string.
   */
  static bool EXPECT_EQ_STRING(const BaseLString<char>& expected,
                               UnstableNode&& actual) {
    return EXPECT_EQ_STRING(expected, RichNode(actual));
  }
};

#define EXPECT_RAISE(label, operation) \
  MOZART_TRY(vm) { \
    operation; \
    ADD_FAILURE(); \
  } MOZART_CATCH(vm, kind, node) { \
    EXPECT_EQ(ExceptionKind::ekRaise, kind); \
  } MOZART_ENDTRY(vm)

namespace mut {
  template <class C>
  void PrintTo(const BaseLString<C>& input, std::ostream* out);

  extern template void PrintTo(const BaseLString<char>& input,
                               std::ostream* out);
  extern template void PrintTo(const BaseLString<char16_t>& input,
                               std::ostream* out);
  extern template void PrintTo(const BaseLString<char32_t>& input,
                               std::ostream* out);

  extern template void PrintTo(const BaseLString<unsigned char>& input,
                               std::ostream* out);
}

template <class T>
void PrintTo(const ContainedLString<T>& input, std::ostream* out) {
  mut::PrintTo(input, out);
}

inline
const unsigned char* ustr(const char* str) {
  return reinterpret_cast<const unsigned char*>(str);
}

}

#endif
