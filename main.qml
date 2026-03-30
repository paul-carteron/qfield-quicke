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

  property bool continuousCaptureEnabled: false
  property bool pendingReopenAfterClose: false

  Component.onCompleted: {
    iface.addItemToPluginsToolbar(reopenFeatureFormButton)
  }

  function isActiveLayerPointLayer() {
    return !!(dashBoard
              && dashBoard.activeLayer
              && dashBoard.activeLayer.geometryType() === Qgis.GeometryType.Point)
  }

  function canUseContinuousCapture() {
    return continuousCaptureEnabled && isActiveLayerPointLayer()
  }

  function disableContinuousCapture(message) {
    continuousCaptureEnabled = false
    pendingReopenAfterClose = false

    if (message)
      mainWindow.displayToast(message)
  }

  function updateFeatureGeometryFromGnss() {
    let position = positionSource.positionInformation

    if (positionSource.active && position.latitudeValid && position.longitudeValid) {
      let pos = positionSource.projectedPosition
      let newWkt = "POINT(" + pos.x + " " + pos.y + ")"
      let newGeometry = GeometryUtils.createGeometryFromWkt(newWkt)

      overlayFeatureFormDrawer.featureModel.feature.geometry = newGeometry
    } else {
      mainWindow.displayToast(qsTr("Position GNSS invalide : la géométrie ne sera pas mise à jour"))
    }
  }

  function createEmptyFeature() {
    if (!canUseContinuousCapture())
      return

    let geometry = GeometryUtils.createGeometryFromWkt("")
    let feature = FeatureUtils.createFeature(dashBoard.activeLayer, geometry)

    overlayFeatureFormDrawer.featureModel.feature = feature
    overlayFeatureFormDrawer.featureModel.resetAttributes(true)
    overlayFeatureFormDrawer.state = "Add"
    overlayFeatureFormDrawer.open()
  }

  QfToolButton {
    id: reopenFeatureFormButton

    iconSource: "ic_reload_24dp.svg"
    round: true

    property bool validLayer: isActiveLayerPointLayer()

    bgcolor: continuousCaptureEnabled ? Theme.mainColor :  "#aaaaaa"
    iconColor: continuousCaptureEnabled ? Theme.darkGray : Theme.mainTextDisabledColor

    onClicked: {
      if (!continuousCaptureEnabled) {
        if (!validLayer) {
          mainWindow.displayToast(qsTr("La saisie continue peut être activée uniquement sur une couche points"))
          return
        }

        continuousCaptureEnabled = true
        mainWindow.displayToast(qsTr("Saisie continue activée"))
      } else {
        disableContinuousCapture(qsTr("Saisie continue désactivée"))
      }
    }
  }

  Connections {
    target: dashBoard

    function onActiveLayerChanged() {
      if (continuousCaptureEnabled && !isActiveLayerPointLayer()) {
        disableContinuousCapture(qsTr("Saisie continue désactivée"))
      }
    }
  }

  Connections {
    target: overlayFeatureFormDrawer ? overlayFeatureFormDrawer.featureForm : null

    function onAboutToSave() {
      if (!canUseContinuousCapture())
        return

      updateFeatureGeometryFromGnss()
    }

    function onConfirmed() {
      if (!canUseContinuousCapture())
        return

      pendingReopenAfterClose = true
    }

    function onCancelled() {
      pendingReopenAfterClose = false
    }
  }

  Connections {
    target: overlayFeatureFormDrawer

    function onClosed() {
      if (!canUseContinuousCapture() || !pendingReopenAfterClose)
        return

      pendingReopenAfterClose = false

      Qt.callLater(function() {
        createEmptyFeature()
      })
    }
  }
}