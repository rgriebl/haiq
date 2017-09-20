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
import QtQml 2.12
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12

RowLayout {
    id: root

    property string text
    property alias icon: svgicon
    property var margins: 0

    SvgIcon {
        id: svgicon
        Layout.margins: root.margins
        Layout.alignment: Qt.AlignCenter
        Layout.preferredWidth: implicitHeight
        color: 'white'
        scale: 2

        layer.enabled: true
        layer.samples: 4
        layer.effect: Glow {
            radius: 20
            spread: 0.2
            samples: 41
            color: '#808080'
            cached: true
        }
    }
}
