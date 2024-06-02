import QtQuick
import QtQuick.Shapes as Shapes
import Qt5Compat.GraphicalEffects


Item {
    id: root
    required property int count
    required property var model
    required property int offset
    required property string propertyName
    property alias strokeWidth: path.strokeWidth
    property alias color0: stop0.color
    property alias color1: stop1.color
    property alias color2: stop2.color

    function redrawLine() {
        for (let i = 0; i < root.count; i++) {
            let rect = root.model.get(i + root.offset)["point_" + root.propertyName]
            let pt = shape.mapFromItem(rect, rect.width / 2, rect.height / 2)

            // console.log(i, offset, rect, pt.x, pt.y)

            path.pathElements[i].x = pt.x
            path.pathElements[i].y = pt.y

            // console.log(path.pathElements[i].x, path.pathElements[i].y)
        }
    }


    Rectangle {
        id: gradient
        anchors.fill: parent
        visible: false
        gradient: Gradient {
            GradientStop { id: stop0; position: 0; color: "red" }
            GradientStop { id: stop1; position: 0.5; color: "white" }
            GradientStop { id: stop2; position: 1; color: "blue" }
        }
    }
    Shapes.Shape {
        id: shape
        anchors.fill: parent
        visible: false
        preferredRendererType: Shapes.Shape.CurveRenderer
        Shapes.ShapePath {
            id: path
            strokeColor: "white"
            strokeWidth: 5
            fillColor: "transparent"

            PathMove { }
            Component.onCompleted: {
                for (let i = 1; i < root.count; i++)
                    pathElements.push(pcurve.createObject(this))
            }
        }
    }
    OpacityMask {
        anchors.fill: gradient
        source: gradient
        maskSource: shape
    }
}
