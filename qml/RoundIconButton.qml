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

RoundButton {
    id: root
    property alias scale: svgIcon.scale
    property real paddingScale: 2

    contentItem: SvgIcon {
        id: svgIcon
        anchors.centerIn: parent
        name: parent.icon.name
        scale: 1.5
    }
    
    implicitHeight: Math.max(contentItem.implicitHeight, contentItem.implicitWidth) * paddingScale
    implicitWidth: implicitHeight
}
