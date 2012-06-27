#ifndef __LSTRING_DECL_HH
#define __LSTRING_DECL_HH

#include <cstdlib>
#include <type_traits>
#include <ostream>
#include "mozartcore-decl.hh"
#include "utils-decl.hh"

namespace mozart {

/////////////
// LString //
/////////////


/**
 * An integer indicating the string pair contains a surrogate character.
 */
enum UnicodeErrorReason : nativeint {
  empty = 0,        // not really an error...
  outOfRange = -1,  // the code point is outside of the valid range 0 -- 0x10ffff
  surrogate = -2,   // the code point refers to a surrogate 0xd800 -- 0xdfff
  invalidUTF8 = -3, // an invalid UTF-8 sequence is provided.
  invalidUTF16 = -4,// an invalid UTF-16 sequence is provided.
  truncated = -5,   // the data is truncated such that an incomplete code unit exists.
  indexOutOfBounds = -6,// index out-of-bounds, available only with 'sliceByCodePoints'.

  invalidUTFNative  // an invalid UTF sequence (based on nchar) is provided
    = std::is_same<nchar, char16_t>::value ? invalidUTF16 :
      std::is_same<nchar, char>::value ? invalidUTF8 : outOfRange
};

namespace mut { // mut = mutable (which is a keyword in C++.)

  // BaseLString ---------------------------------------------------------------

  template <class C>
  struct BaseLString {  // LString = Length-prefixed string.
    const C* string;
    union {
      nativeint length;
      UnicodeErrorReason error;
    };

    constexpr bool isError() const { return length < 0; }
    constexpr bool isErrorOrEmpty() const { return length <= 0; }

    constexpr size_t bytesCount() const { return length * sizeof(C); }

    const C* begin() const { return string; }
    const C* end() const { return string + length; }

    constexpr C operator[](nativeint i) const { return string[i]; }

    // Initialize with nothing.
    constexpr BaseLString() : string(nullptr), length(0) {}
    constexpr BaseLString(std::nullptr_t) : string(nullptr), length(0) {}

    // Initialize with an error.
    constexpr BaseLString(UnicodeErrorReason error)
        : string(nullptr), error(error) {}

    // Can be moved.
    inline BaseLString(BaseLString&& other);
    // Not copyable by default.
    BaseLString(const BaseLString&) = delete;
    BaseLString& operator=(const BaseLString&) = delete;

    // Initialize from string and length.
    constexpr BaseLString(const C* str, nativeint len)
        : string(str), length(len) {}
    template <nativeint n>
    constexpr BaseLString(const C (&str)[n], nativeint len=n-1)
        : string(str), length(len) {}

    // Initialize from C string.
    inline BaseLString(const C* str);

    // Slice the string. This operation is unsafe, because the resulting string
    // will become invalid when the source string goes out of scope.
    constexpr const BaseLString unsafeSlice(nativeint from) const;
    constexpr const BaseLString unsafeSlice(nativeint from, nativeint to) const;
  };

  // Equality testing.
  template <class C>
  static
  bool operator==(const BaseLString<C>& a, const BaseLString<C>& b);
  template <class C>
  static
  bool operator!=(const BaseLString<C>& a, const BaseLString<C>& b);

  template <class C, nativeint n>
  static bool operator==(const C (&str)[n], const BaseLString<C>& b) {
    return BaseLString<C>(str) == b;
  }
  template <class C, nativeint n>
  static bool operator==(const BaseLString<C>& a, const C (&str)[n]) {
    return a == BaseLString<C>(str);
  }


  /**
   * Write the string to an output stream.
   */
  template <class C>
  static std::basic_ostream<C>& operator<<(std::basic_ostream<C>& out,
                                           const BaseLString<C>& input);

  // LString -------------------------------------------------------------------
  // "The" LString with persistent/VM storage.
  template <class C>
  struct LString : BaseLString<C> {
    // Initialize from string literal.
    // (Based on http://stackoverflow.com/a/2041727/224671, obviously not
    //  fool-proof.)
    template <nativeint n>
    constexpr LString(const C (&str)[n], nativeint len=n-1)
        : BaseLString<C>(str, len) {}
    template <nativeint n>
    LString(C (&str)[n], nativeint len=n-1) = delete;

    constexpr LString(UnicodeErrorReason e) : BaseLString<C>(e) {}

    // LString is copyable (aliasable).
    constexpr LString(const LString& s) : BaseLString<C>(s.string, s.length) {}

    // Copy-construct with help of VM.
    inline LString(VM vm, const BaseLString<C>& other);
    LString(VM vm, const LString<C>& other)
        : LString(vm, static_cast<const BaseLString<C>&>(other)) {}

    template <class F>
    inline LString(VM vm, nativeint length, const F& initializer);

    // Only LString can be safely sliced.
    inline constexpr const LString slice(nativeint from, nativeint to) const;
    inline constexpr const LString slice(nativeint from) const;

    template <nativeint n>
    static constexpr const LString<C>
        fromLiteral(const C (&str)[n], nativeint len=n-1) { return {str, len}; }

  private:
    constexpr LString(const C* str, nativeint len) : BaseLString<C>(str, len) {}
  };
}

// ContainedLString ----------------------------------------------------------
// LString with an STL container backend.

template <class T>
struct ContainedLString : mut::BaseLString<typename T::value_type> {
  typedef typename T::value_type CharType;

  inline ContainedLString(T container);
  inline ContainedLString(ContainedLString&& other);

  template <class It>
  ContainedLString(It begin, It end) : ContainedLString(T(begin, end)) {}

  // Insert a string at the beginning of the container.
  inline void insertPrefix(const mut::BaseLString<CharType>& prefix);

  constexpr ContainedLString(UnicodeErrorReason reason)
        : mut::BaseLString<CharType>(reason) {}

private:
  T _container;
};

#if defined(__clang__) || !defined(__GNUC__)

// The default view is immutable.
template <class C> using LString = const mut::LString<C>;
template <class C> using BaseLString = const mut::BaseLString<C>;

#else

// Note: gcc users can only "be careful", because of bug 53026.
// - http://gcc.gnu.org/bugzilla/show_bug.cgi?id=53026
using namespace mut;

#endif

// Make BaseLString from local buffer
template <class C>
static mut::BaseLString<C> makeLString(const C* str);
template <class C>
static mut::BaseLString<C> makeLString(const C* str, nativeint len);

// Create LString on heap.
template <class C, nativeint n>
inline LString<C> newLString(const C (&str)[n], nativeint len=n-1);
template <class C, nativeint n>
LString<C> newLString(C (&str)[n], nativeint len=n-1) = delete;

template <class C>
inline LString<C> newLString(VM vm, const C* str);
template <class C>
static LString<C> newLString(VM vm, const C* str, nativeint len);
template <class T>
static LString<typename T::value_type> newLString(VM vm, const T& container);
template <class C>
static LString<C> newLString(VM vm, const BaseLString<C>& copyFrom);
template <class F>
static auto newLString(VM vm, nativeint len, const F& func)
    -> LString<typename std::remove_pointer<
                 typename function_traits<F>::template arg<0>::type>::type>;

// Concatenate two LString's.
template <class C>
static LString<C> concatLString(VM vm, const LString<C>& a, const LString<C>& b);

}

#endif

