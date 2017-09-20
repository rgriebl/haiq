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
import QtQml 2.0
import QtQuick 2.0

Rectangle {
	width: text.paintedWidth
	height: text.paintedHeight

	visible: fpsProbe.fps >= 0
	color: {
		if (fpsProbe.fps < 30)
			return "red";
		if (fpsProbe.fps < 45)
			return "orange"
		else
			return "green" 
	}

	Text {
		id: text
		font.pixelSize: 20;
		text: fpsProbe.fps + " fps"
	}

	Timer {
		id: fpsProbe

        property int fps: -1
        property int frames: 0

        property double previousTime: 0

        repeat: true
        interval: 1000
        running: true
        
        onTriggered: {
        	if (!previousTime)
        		previousTime = new Date().getTime();
     
     	 	var currentTime = new Date().getTime();

        	fps = frames / ((currentTime - previousTime) / 1000);    
            frames = 0;

            previousTime = currentTime;
        }

        property real frameObserver
		NumberAnimation on frameObserver {
			from: 0; to: 1;
			loops: Animation.Infinite;
			duration: 1000
		}

		onFrameObserverChanged: {
			frames++;
			update();
		}
    }
}
