#include "mozart.hh"
#include <gtest/gtest.h>
#include "testutils.hh"

using namespace mozart;

class GCTest : public MozartTest {};

TEST_F(GCTest, GCSanity) {
    // This is to ensure the GC does release memory allocated on the VM, and to
    // ensure 'requestGC' does invoke the GC when the VM is running.

    // 0. Start in a non-degenerate case
    vm->requestGC();
    vm->run();

    // 1. Check that the size does increase after we allocate something.
    size_t original_size = vm->getMemoryManager().getAllocated();
    auto unit_node = build(vm, unit);
    auto something = Array::build(vm, 256, 0, unit_node);
    size_t new_size = vm->getMemoryManager().getAllocated();
    EXPECT_LT(original_size, new_size);

    // 2. Ensure the memory is not lost without running the GC.
    vm->run();
    EXPECT_EQ(new_size, vm->getMemoryManager().getAllocated());

    // 3. Ensure the memory is released when we run the GC.
    vm->requestGC();
    vm->run();
    EXPECT_EQ(original_size, vm->getMemoryManager().getAllocated());

    (void) something;   // shut up warning.
}

TEST_F(GCTest, Protect) {
    // This is to ensure protected nodes are noticed by GC, and thus won't be
    // freed.

    // 0. Start in a non-degenerate case
    vm->requestGC();
    vm->run();

    // 1. Check that the size does increase after we allocate something.
    size_t original_size = vm->getMemoryManager().getAllocated();
    auto unit_node = build(vm, unit);
    auto array_node = Array::build(vm, 250, 0, unit_node);
    {
        auto key = build(vm, 18);
        auto value = build(vm, 1902);
        ArrayLike(array_node).arrayPut(vm, key, value);
    }
    EXPECT_LT(original_size, vm->getMemoryManager().getAllocated());

    // 2. Protect a node, and try to run the GC. Verify it is not freed and has
    //    the correct value.
    auto protected_array_node = vm->protect(array_node);
    EXPECT_TRUE(RichNode(*protected_array_node).isSameNode(array_node));

    vm->requestGC();
    vm->run();
    vm->requestGC();  // we perform GC twice to ensure memory are really erased.
    vm->run();

    EXPECT_LT(original_size, vm->getMemoryManager().getAllocated());
    {
        auto key = build(vm, 18);
        auto value = ArrayLike(*protected_array_node).arrayGet(vm, key);
        EXPECT_EQ_INT(1902, value);
    }

    // 3. Unprotect a node, and run the GC again. Verify it is freed.
    protected_array_node.reset();
    vm->requestGC();
    vm->run();
    vm->requestGC();
    vm->run();

    EXPECT_EQ(original_size, vm->getMemoryManager().getAllocated());
}

TEST_F(GCTest, ProtectedNodeConversionWithSharedPtr) {
    // ProtectedNode must be convertible to and from
    // std::shared_ptr<StableNode*>

    std::shared_ptr<StableNode*> some_shared_ptr = vm->protect(build(vm, 123));

    vm->requestGC();
    vm->run();

    ProtectedNode protected_node = some_shared_ptr;
    EXPECT_EQ_INT(123, *protected_node);
}

TEST_F(GCTest, ProtectTwice) {
    // This is to check protecting the same stable node twice is safe.

    StableNode node;
    node.init(vm, build(vm, 402));

    auto protected_1 = vm->protect(node);
    auto protected_2 = vm->protect(node);

    #define CHECK(message) \
        SCOPED_TRACE(::testing::Message() << message << ": " << &node << "; " \
                                          << (protected_1 ? &(*protected_1) : nullptr) << ", " \
                                          << (protected_2 ? &(*protected_2) : nullptr))

    {
        CHECK("sanity");
        EXPECT_EQ_INT(402, *protected_1);
        EXPECT_EQ_INT(402, *protected_2);
    }

    vm->requestGC();
    vm->run();

    {
        CHECK("pre 2nd-gc");
        EXPECT_EQ_INT(402, *protected_1);
        EXPECT_EQ_INT(402, *protected_2);
    }

    vm->requestGC();
    vm->run();

    {
        CHECK("pre unprotect");
        EXPECT_EQ_INT(402, *protected_1);
        EXPECT_EQ_INT(402, *protected_2);
    }

    protected_1.reset();

    {
        CHECK("post unprotect");
        EXPECT_EQ_INT(402, *protected_2);
    }

    vm->requestGC();
    vm->run();
    vm->requestGC();
    vm->run();

    {
        CHECK("post 4th-gc");
        EXPECT_EQ_INT(402, *protected_2);
    }
}

TEST_F(GCTest, ProtectTwiceUncopyable) {
    // This is to check protecting the same uncopyable stable node twice is safe.

    StableNode node;
    node.init(vm, buildList(vm, 123, 456, 789));

    auto protected_1 = vm->protect(node);
    auto protected_2 = vm->protect(node);

    {
        CHECK("sanity");
        auto expected = buildList(vm, 123, 456, 789);
        EXPECT_TRUE(equals(vm, expected, *protected_1));
        EXPECT_TRUE(equals(vm, expected, *protected_2));
        EXPECT_TRUE(RichNode(*protected_1).isSameNode(*protected_2));
    }

    vm->requestGC();
    vm->run();

    {
        CHECK("pre unprotect");
        auto expected = buildList(vm, 123, 456, 789);
        EXPECT_TRUE(equals(vm, expected, *protected_1));
        EXPECT_TRUE(equals(vm, expected, *protected_2));
        EXPECT_TRUE(RichNode(*protected_1).isSameNode(*protected_2));
    }

    protected_1.reset();

    {
        CHECK("post unprotect");
        auto expected = buildList(vm, 123, 456, 789);
        EXPECT_TRUE(equals(vm, expected, *protected_2));
    }

    vm->requestGC();
    vm->run();

    {
        CHECK("post 2nd-gc");
        auto expected = buildList(vm, 123, 456, 789);
        EXPECT_TRUE(equals(vm, expected, *protected_2));
    }

    #undef CHECK
}

class InstanceCounter {
public:
  InstanceCounter(int& instanceCount): _instanceCount(&instanceCount) {
    ++*_instanceCount;
  }

  ~InstanceCounter() {
    --*_instanceCount;
  }
private:
  int* _instanceCount;
};

TEST_F(GCTest, InstanceCounterSanityTest) {
  // Sanity test for InstanceCounter

  int instanceCount = 0;

  auto firstInstance = std::make_shared<InstanceCounter>(instanceCount);
  EXPECT_EQ(1, instanceCount);

  auto secondInstance = std::make_shared<InstanceCounter>(instanceCount);
  EXPECT_EQ(2, instanceCount);

  firstInstance.reset();
  EXPECT_EQ(1, instanceCount);

  secondInstance.reset();
  EXPECT_EQ(0, instanceCount);
}

TEST_F(GCTest, DestroyForeignPointerWhenNotReferenced) {
  int instanceCount = 0;

  auto sharedInstance = std::make_shared<InstanceCounter>(instanceCount);
  auto weakInstance = std::weak_ptr<InstanceCounter>(sharedInstance);

  UnstableNode foreign = build(vm, sharedInstance);
  EXPECT_EQ(ForeignPointer::type(), RichNode(foreign).type());

  // 1 reference in sharedInstance, and 1 in the ForeignPointer
  EXPECT_EQ(2, weakInstance.use_count());

  sharedInstance.reset();

  // 1 reference in ForeignPointer
  EXPECT_EQ(1, weakInstance.use_count());
  EXPECT_EQ(1, instanceCount);

  vm->requestGC();
  vm->run();

  /* Since there were no reference to `foreign`, the instance should have
   * been destroyed. */

  EXPECT_EQ(0, weakInstance.use_count());
  EXPECT_EQ(0, instanceCount);
}

TEST_F(GCTest, KeepForeignPointerWhenReferenced) {
  int instanceCount = 0;

  auto sharedInstance = std::make_shared<InstanceCounter>(instanceCount);
  auto weakInstance = std::weak_ptr<InstanceCounter>(sharedInstance);

  UnstableNode foreign = build(vm, sharedInstance);
  EXPECT_EQ(ForeignPointer::type(), RichNode(foreign).type());

  // 1 reference in sharedInstance, and 1 in the ForeignPointer
  EXPECT_EQ(2, weakInstance.use_count());

  sharedInstance.reset();

  // 1 reference in ForeignPointer
  EXPECT_EQ(1, weakInstance.use_count());
  EXPECT_EQ(1, instanceCount);

  // We protect `foreign` to ensure it is kept by GC
  auto protectedForeign = vm->protect(foreign);

  vm->requestGC();
  vm->run();

  // There must still be 1 reference in the ForeignPointer
  EXPECT_EQ(1, weakInstance.use_count());
  EXPECT_EQ(1, instanceCount);

  // Now we release it
  protectedForeign.reset();

  vm->requestGC();
  vm->run();

  /* Since there were no reference to `foreign`, the instance should have
   * been destroyed. */

  EXPECT_EQ(0, weakInstance.use_count());
  EXPECT_EQ(0, instanceCount);
}

TEST_F(GCTest, ForeignPointerMatchesGoodType) {
  using namespace ::mozart::patternmatching;

  UnstableNode foreign0 = build(vm, std::make_shared<int>(5));
  RichNode foreign = foreign0;

  EXPECT_EQ(ForeignPointer::type(), foreign.type());
  EXPECT_TRUE(foreign.as<ForeignPointer>().isPointer<int>());
  EXPECT_FALSE(foreign.as<ForeignPointer>().isPointer<bool>());

  std::shared_ptr<int> sharedInt;
  if (matches(vm, foreign, capture(sharedInt))) {
    EXPECT_EQ(5, *sharedInt);
  } else {
    ADD_FAILURE();
  }

  std::shared_ptr<double> sharedDouble;
  EXPECT_FALSE(matches(vm, foreign, capture(sharedDouble)));
}
