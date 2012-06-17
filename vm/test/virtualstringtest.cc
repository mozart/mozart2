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

        testNodes[13].make<Atom>(vm, NSTR("f-o"));
        testNodes[14].make<Atom>(vm, NSTR("nil"));
        testNodes[15].make<Atom>(vm, NSTR("#"));
        testNodes[16].make<Atom>(vm, NSTR("\U0010ffff\U0010ffff"));

        testNodes[17].make<Boolean>(vm, true);
        testNodes[18].make<Boolean>(vm, false);

        testNodes[19].make<Unit>(vm);

        testNodes[20].make<Cons>(vm, NSTR("f-o"));
        testNodes[21].make<Cons>(vm, NSTR("nil"));
        testNodes[22].make<Cons>(vm, NSTR("#"));
        testNodes[23].make<Cons>(vm, NSTR("\U0010ffff\U0010ffff"));

        testNodes[24] = buildCons(vm, 0x40, buildCons(vm, 0x60, vm->coreatoms.nil));
        testNodes[25] = buildCons(vm, 0x40000, buildCons(vm, 0x60000, vm->coreatoms.nil));
        testNodes[26] = buildCons(vm, 0x40000, Cons::build(vm, NSTR("60000")));

        testNodes[27] = buildTuple(vm, vm->coreatoms.sharp, 123, 456);
        testNodes[28] = buildTuple(vm, vm->coreatoms.sharp, NSTR("f-o"), NSTR("nil"), 6);
        testNodes[29] = buildTuple(vm, vm->coreatoms.sharp,
                                    Cons::build(vm, NSTR("\U00012345")),
                                    -12345,
                                    Cons::build(vm, NSTR("-12345")),
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
        NSTR("0"), NSTR("4"), NSTR("-4"), NSTR("12300000"), NSTR("-12300000"),
        NSTR("3.125"), NSTR("-3.125"), NSTR("9.0e125"), NSTR("-9.0e125"),
            NSTR("9.0e-125"), NSTR("-9.0e-125"), NSTR("9.5678e125"), NSTR("9.0"),
        NSTR("f-o"), NSTR(""), NSTR(""), NSTR("\U0010ffff\U0010ffff"),
        NSTR("true"), NSTR("false"), NSTR("unit"),
        NSTR("f-o"), NSTR("nil"), NSTR("#"), NSTR("\U0010ffff\U0010ffff"),
        NSTR("\u0040\u0060"), NSTR("\U00040000\U00060000"),
            NSTR("\U0004000060000"),
        NSTR("123456"), NSTR("f-o6"), NSTR("\U00012345-12345-12345-1-2-3-4-5"),
        minStr,
        NSTR("\u0070\u0080\u0090"),
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
        NSTR("0"), NSTR("4"), NSTR("****4"), NSTR("12300000"), NSTR("****12300000"),
        NSTR("3.125"), NSTR("****3.125"), NSTR("9.0e125"), NSTR("****9.0e125"),
            NSTR("9.0e****125"), NSTR("****9.0e****125"), NSTR("9.5678e125"),
            NSTR("9.0"),
        NSTR("f-o"), NSTR(""), NSTR(""), NSTR("\U0010ffff\U0010ffff"),
        NSTR("true"), NSTR("false"), NSTR("unit"),
        NSTR("f-o"), NSTR("nil"), NSTR("#"), NSTR("\U0010ffff\U0010ffff"),
        NSTR("\u0040\u0060"), NSTR("\U00040000\U00060000"),
            NSTR("\U0004000060000"),
        NSTR("123456"), NSTR("f-o6"),
            NSTR("\U00012345****12345-12345****1****2****3****4****5"),
        NSTR("****") + minStr.substr(1),
        NSTR("\u0070\u0080\u0090"),
    };

    UnstableNode replacement = Cons::build(vm, NSTR("****"));

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
        buildCons(vm, Cons::build(vm, NSTR("foo")), vm->coreatoms.nil),
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

