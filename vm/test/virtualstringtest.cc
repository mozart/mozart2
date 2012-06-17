#include <tuple>
#include "mozart.hh"
#include <gtest/gtest.h>
#include "testutils.hh"

using namespace mozart;

class VirtualStringTest : public MozartTest {
protected:
    UnstableNode testNodes[32];
    std::basic_string<nchar> minStr;

    virtual void SetUp() {
        testNodes[0].make<SmallInt>(vm, 0);
        testNodes[1].make<SmallInt>(vm, 4);
        testNodes[2].make<SmallInt>(vm, -4);
        testNodes[3].make<SmallInt>(vm, 12300000);
        testNodes[4].make<SmallInt>(vm, -12300000);

        testNodes[5].make<Float>(vm, 3.125);
        testNodes[6].make<Float>(vm, -3.125);
        testNodes[7].make<Float>(vm, 9.0e125);
        testNodes[8].make<Float>(vm, -9.0e125);
        testNodes[9].make<Float>(vm, 9.0e-125);
        testNodes[10].make<Float>(vm, -9.0e-125);
        testNodes[11].make<Float>(vm, 9.5678e125);
        testNodes[12].make<Float>(vm, 9.0);

        testNodes[13].make<Atom>(vm, MOZART_STR("f-o"));
        testNodes[14].make<Atom>(vm, MOZART_STR("nil"));
        testNodes[15].make<Atom>(vm, MOZART_STR("#"));
        testNodes[16].make<Atom>(vm, MOZART_STR("\U0010ffff\U0010ffff"));

        testNodes[17].make<Boolean>(vm, true);
        testNodes[18].make<Boolean>(vm, false);

        testNodes[19].make<Unit>(vm);

        testNodes[20].make<String>(vm, MOZART_STR("f-o"));
        testNodes[21].make<String>(vm, MOZART_STR("nil"));
        testNodes[22].make<String>(vm, MOZART_STR("#"));
        testNodes[23].make<String>(vm, MOZART_STR("\U0010ffff\U0010ffff"));

        testNodes[24] = buildCons(vm, 0x40, buildCons(vm, 0x60, vm->coreatoms.nil));
        testNodes[25] = buildCons(vm, 0x40000, buildCons(vm, 0x60000, vm->coreatoms.nil));
        testNodes[26] = buildCons(vm, 0x40000, String::build(vm, MOZART_STR("60000")));

        testNodes[27] = buildTuple(vm, vm->coreatoms.sharp, 123, 456);
        testNodes[28] = buildTuple(vm, vm->coreatoms.sharp, MOZART_STR("f-o"), MOZART_STR("nil"), 6);
        testNodes[29] = buildTuple(vm, vm->coreatoms.sharp,
                                    String::build(vm, MOZART_STR("\U00012345")),
                                    -12345,
                                    String::build(vm, MOZART_STR("-12345")),
                                    buildTuple(vm, vm->coreatoms.sharp, -1, -2, -3),
                                    -4,
                                    -5);

        testNodes[30].make<SmallInt>(vm, std::numeric_limits<nativeint>::min());
        testNodes[31].make<ByteString>(vm, "\x70\x80\x90");

        auto s = std::to_string(std::numeric_limits<nativeint>::min());
        std::copy(s.cbegin(), s.cend(), std::back_inserter(minStr));
    }

    virtual void TearDown() {
        /*
        for (auto& node : testNodes) {
            node.reset(vm);
        }
        */
    }
};

TEST_F(VirtualStringTest, IsVirtualString) {
    for (auto&& node : testNodes) {
        bool res = false;
        if (EXPECT_PROCEED(VirtualString(node).isVirtualString(vm, res))) {
            EXPECT_TRUE(res);
        }
    }
}

TEST_F(VirtualStringTest, ToString) {
    std::basic_string<nchar> results[] = {
        MOZART_STR("0"), MOZART_STR("4"), MOZART_STR("-4"), MOZART_STR("12300000"), MOZART_STR("-12300000"),
        MOZART_STR("3.125"), MOZART_STR("-3.125"), MOZART_STR("9.0e125"), MOZART_STR("-9.0e125"),
            MOZART_STR("9.0e-125"), MOZART_STR("-9.0e-125"), MOZART_STR("9.5678e125"), MOZART_STR("9.0"),
        MOZART_STR("f-o"), MOZART_STR(""), MOZART_STR(""), MOZART_STR("\U0010ffff\U0010ffff"),
        MOZART_STR("true"), MOZART_STR("false"), MOZART_STR("unit"),
        MOZART_STR("f-o"), MOZART_STR("nil"), MOZART_STR("#"), MOZART_STR("\U0010ffff\U0010ffff"),
        MOZART_STR("\u0040\u0060"), MOZART_STR("\U00040000\U00060000"),
            MOZART_STR("\U0004000060000"),
        MOZART_STR("123456"), MOZART_STR("f-o6"), MOZART_STR("\U00012345-12345-12345-1-2-3-4-5"),
        minStr,
        MOZART_STR("\u0070\u0080\u0090"),
    };

    size_t i = 0;
    for (auto&& node : testNodes) {
        std::basic_ostringstream<nchar> stringStream;
        if (EXPECT_PROCEED(VirtualString(node).toString(vm, stringStream))) {
            EXPECT_EQ(results[i], stringStream.str());
        }
        ++ i;
    }
}

TEST_F(VirtualStringTest, Length) {
    nativeint results[] = {
        1, 1, 2, 8, 9,
        5, 6, 7, 8, 8, 9, 10, 3,
        3, 0, 0, 2,
        4, 5,
        4,
        3, 3, 1, 2,
        2, 2, 6,
        6, 4, 23,
        (nativeint) minStr.length(),
        3,
    };

    size_t i = 0;
    for (auto&& node : testNodes) {
        nativeint length;
        if (EXPECT_PROCEED(VirtualString(node).vsLength(vm, length))) {
            EXPECT_EQ(results[i], length);
        }
        ++ i;
    }
}

TEST_F(VirtualStringTest, ChangeSign) {
    std::basic_string<nchar> results[] = {
        MOZART_STR("0"), MOZART_STR("4"), MOZART_STR("****4"), MOZART_STR("12300000"), MOZART_STR("****12300000"),
        MOZART_STR("3.125"), MOZART_STR("****3.125"), MOZART_STR("9.0e125"), MOZART_STR("****9.0e125"),
            MOZART_STR("9.0e****125"), MOZART_STR("****9.0e****125"), MOZART_STR("9.5678e125"),
            MOZART_STR("9.0"),
        MOZART_STR("f-o"), MOZART_STR(""), MOZART_STR(""), MOZART_STR("\U0010ffff\U0010ffff"),
        MOZART_STR("true"), MOZART_STR("false"), MOZART_STR("unit"),
        MOZART_STR("f-o"), MOZART_STR("nil"), MOZART_STR("#"), MOZART_STR("\U0010ffff\U0010ffff"),
        MOZART_STR("\u0040\u0060"), MOZART_STR("\U00040000\U00060000"),
            MOZART_STR("\U0004000060000"),
        MOZART_STR("123456"), MOZART_STR("f-o6"),
            MOZART_STR("\U00012345****12345-12345****1****2****3****4****5"),
        MOZART_STR("****") + minStr.substr(1),
        MOZART_STR("\u0070\u0080\u0090"),
    };

    UnstableNode replacement = String::build(vm, MOZART_STR("****"));

    size_t i = 0;
    for (auto&& node : testNodes) {
        UnstableNode newVs;
        if (EXPECT_PROCEED(VirtualString(node).vsChangeSign(vm, replacement, newVs))) {
            std::basic_ostringstream<nchar> newVsStream;
            if (EXPECT_PROCEED(VirtualString(newVs).toString(vm, newVsStream))) {
                newVsStream.flush();
                EXPECT_EQ(results[i], newVsStream.str());
            }
        }
        ++ i;
    }
}

TEST_F(VirtualStringTest, IsNotVirtualString) {
    UnstableNode nodes[] = {
        OptName::build(vm),
        buildCons(vm, 0xd800, buildCons(vm, 0xdc00, vm->coreatoms.nil)),
        buildCons(vm, 0x110000, vm->coreatoms.nil),
        buildCons(vm, String::build(vm, MOZART_STR("foo")), vm->coreatoms.nil),
        buildCons(vm, 0x40, vm->coreatoms.typeError),
        buildTuple(vm, vm->coreatoms.typeError, 2, 2),
        buildTuple(vm, vm->coreatoms.sharp, 10, OptName::build(vm)),
    };

    for (auto& node : nodes) {
        bool res = true;
        if (EXPECT_PROCEED(VirtualString(node).isVirtualString(vm, res))) {
            EXPECT_FALSE(res);
        }
    }
}

