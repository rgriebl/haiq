/* Copyright (C) 2017-2022 Robert Griebl. All rights reserved.
**
** This file is part of HAiQ.
**
** This file may be distributed and/or modified under the terms of the GNU
** General Public License version 2 as published by the Free Software Foundation
** and appearing in the file LICENSE.GPL included in the packaging of this file.
**
** This file is provided AS IS with NO WARRANTY OF ANY KIND, INCLUDING THE
** WARRANTY OF DESIGN, MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
**
** See http://fsf.org/licensing/licenses/gpl.html for GPL licensing information.
*/

#include "lzutf8.h"

QByteArray LZUTF8::decompress(const QByteArray &data)
{
    QByteArray utf8;
    utf8.reserve(data.size());

    uint dataLen = uint(data.size());
    for (uint i = 0; i < dataLen; ++i) {
        const unsigned char c = data.at(i);
        const unsigned char c2 = ((i + 1) < dataLen) ? data.at(i + 1) : 0b10000000;
        const unsigned char c3 = ((i + 2) < dataLen) ? data.at(i + 2) : 0;
        const unsigned char upper = (c & 0b11100000);

        if (((upper == 0b11100000) || (upper == 0b11000000)) && !(c2 & 0b10000000)) {
            // decompress
            int len  = c & 0b00011111;
            int dist = 0;
            ++i;
            if (upper == 0b11000000) {
                dist = c2;
            } else {
                dist = int(c2) << 8 | c3;
                ++i;
            }

            int matchPos = utf8.size() - dist;

            for (int j = 0; j < len; ++j)
                utf8.append(utf8.at(matchPos + j));
        } else {
            utf8.append(c);
        }
    }
    return utf8;
}
