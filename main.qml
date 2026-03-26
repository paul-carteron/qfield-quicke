import QtQuick
import QtQuick.Controls

import org.qfield
import org.qgis
import Theme

import "qrc:/qml" as QFieldItems

Item {
  id: plugin

  property var mainWindow: iface.mainWindow()
  property var dashBoard: iface.findItemByObjectName("dashBoard")
  property var overlayFeatureFormDrawer: iface.findItemByObjectName("overlayFeatureFormDrawer")
  property var positionSource: iface.findItemByObjectName("positionSource")
  property var toolbar: iface.findItemByObjectName("toolbar")

  property bool reopenFeatureForm: false

  Component.onCompleted: {
    iface.addItemToPluginsToolbar(reopenFeatureFormButton)
  }

  QfToolButton {
    id: reopenFeatureFormButton

    iconSource: "ic_reload_24dp.svg"
    round: true
    bgcolor: reopenFeatureForm ? Theme.goodColor : Theme.darkGray
    iconColor: reopenFeatureForm ? Theme.darkGray : Theme.goodColor

    onClicked: {
      reopenFeatureForm = !reopenFeatureForm

    if (reopenFeatureForm) {
      mainWindow.displayToast(qsTr("QuickE activé"))
    } else {
      mainWindow.displayToast(qsTr("QuickE désactivé"))
    }
    }
  }

  function createEmptyFeature() {
    let geometry = GeometryUtils.createGeometryFromWkt('')
    let feature = FeatureUtils.createFeature(dashBoard.activeLayer, geometry)

    overlayFeatureFormDrawer.featureModel.feature = feature
    overlayFeatureFormDrawer.featureModel.resetAttributes(true)
    overlayFeatureFormDrawer.state = 'Add'
    overlayFeatureFormDrawer.open()
  }

  Connections {
    target: overlayFeatureFormDrawer ? overlayFeatureFormDrawer.featureForm : null

    function onAboutToSave() {
      if (!reopenFeatureForm)
        return

      let position = positionSource.positionInformation

      if (positionSource.active && position.latitudeValid && position.longitudeValid) {
        let pos = positionSource.projectedPosition
        let newWkt = "POINT(" + pos.x + " " + pos.y + ")"
        let newGeometry = GeometryUtils.createGeometryFromWkt(newWkt)

        overlayFeatureFormDrawer.featureModel.feature.geometry = newGeometry
      } else {
        mainWindow.displayToast(qsTr("GNSS position is not valid."))
      }
    }

    function onConfirmed() {
      if (reopenFeatureForm)
        preNewFeatureTimer.start()
    }
  }

  Timer {
    id: preNewFeatureTimer
    interval: 10
    repeat: false

    onTriggered: {
      createEmptyFeature()
    }
  }

}