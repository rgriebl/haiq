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
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.impl 2.12

IconImage {
    id: root

    property string prefix: ''
    property string icon
    property real size: font.pixelSize
    property real scale: 1

    fillMode: Image.PreserveAspectFit

    color: palette.text
//    sourceSize.width: root.size * root.scale
    sourceSize.height: root.size * root.scale
    source: root.icon ? Qt.resolvedUrl('/icons/' + root.prefix + root.icon + '.svg') : ''
}
