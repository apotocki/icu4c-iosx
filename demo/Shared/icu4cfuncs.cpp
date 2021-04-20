//
//  icu4cfuncs.cpp
//  icu4c-demo
//
//  Created by Alexander Pototskiy on 20.04.21.
//

#include "icu4cfuncs.hpp"

#include <string>
#include <cstring>

#define U_HIDE_DEPRECATED_API

#include <unicode/unistr.h>

namespace icu = U_ICU_NAMESPACE;

extern "C"
int toUpper(const char* str, char* rstr, uint32_t sz)
{
    using namespace icu;
    UnicodeString ucs = UnicodeString::fromUTF8(StringPiece(str));
    ucs.toUpper();
    std::string result;
    ucs.toUTF8String(result);
    if (result.size() > sz - 1) {
        return 0;
    }
    std::memcpy(rstr, result.c_str(), result.size());
    rstr[result.size()] = 0;
    return 1;
}
