#include "mozart.hh"
#include <gtest/gtest.h>
#include "testutils.hh"

using namespace mozart;

class GCTest : public MozartTest {};

TEST_F(GCTest, GCSanity) {
    // This is to ensure the GC does release memory allocated on the VM, and to
    // ensure 'requestGC' does invoke the GC when the VM is running.

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

