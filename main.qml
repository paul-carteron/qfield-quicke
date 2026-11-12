import QtQuick
import QtQuick.Controls

import org.qfield
import org.qgis
import Theme

Item {
  id: plugin

  property var mainWindow: iface.mainWindow()
  property var dashboard: iface.findItemByObjectName("dashBoard")
  property var featureFormDrawer: iface.findItemByObjectName("overlayFeatureFormDrawer")
  property var featureForm: featureFormDrawer ? featureFormDrawer.featureForm : null
  property var featureModel: featureFormDrawer ? featureFormDrawer.featureModel : null
  property var positionSource: iface.findItemByObjectName("positionSource")

  property bool continuousCaptureEnabled: false
  // Remember Add mode because QField switches to Edit before confirming the save.
  // aboutToSave() -> Save the feature -> state = "Edit" -> confirmed()
  property bool saveStartedInAddMode: false
  // Layer to reuse after a confirmed new-feature save.
  property var nextFeatureLayer: null

  Component.onCompleted: {
    iface.addItemToPluginsToolbar(pluginButton)
  }

  function isPointLayer(layer) {
    return !!layer && layer.geometryType() === Qgis.GeometryType.Point
  }

  function canUseContinuousCapture() {
    return continuousCaptureEnabled && !!featureModel && isPointLayer(featureModel.currentLayer)
  }

  function disableContinuousCapture(message) {
    continuousCaptureEnabled = false
    saveStartedInAddMode = false
    nextFeatureLayer = null

    if (message)
      mainWindow.displayToast(message)
  }

  function updateFeatureGeometryFromGnss() {
    const position = positionSource.positionInformation
    if (!positionSource.active || !position.latitudeValid || !position.longitudeValid) {
      mainWindow.displayToast(qsTr("Position GNSS invalide : la géométrie ne sera pas mise à jour"))
      return
    }

    // Convert the positioning coordinates into the form's layer CRS.
    const positionInLayerCrs = GeometryUtils.reprojectPoint(
      positionSource.projectedPosition,
      positionSource.coordinateTransformer.destinationCrs,
      featureModel.currentLayer.crs)
    const pointWkt = "POINT(" + positionInLayerCrs.x + " " + positionInLayerCrs.y + ")"
    featureModel.feature.geometry = GeometryUtils.createGeometryFromWkt(pointWkt)
  }

  function createEmptyFeature(layer) {
    if (!continuousCaptureEnabled || !isPointLayer(layer) || featureFormDrawer.visible)
      return

    const geometry = GeometryUtils.createGeometryFromWkt("")
    featureModel.currentLayer = layer
    featureModel.feature = FeatureUtils.createFeature(layer, geometry)
    featureModel.resetAttributes(true)
    featureForm.state = "Add"
    featureFormDrawer.open()
  }

  QfToolButton {
    id: pluginButton

    iconSource: "ic_reload_24dp.svg"
    round: true

    bgcolor: continuousCaptureEnabled ? Theme.mainColor :  "#aaaaaa"
    iconColor: continuousCaptureEnabled ? Theme.darkGray : Theme.mainTextDisabledColor

    onClicked: {
      if (continuousCaptureEnabled) {
        disableContinuousCapture(qsTr("Saisie continue désactivée"))
        return
      }

      if (!isPointLayer(dashboard.activeLayer)) {
        mainWindow.displayToast(qsTr("La saisie continue peut être activée uniquement sur une couche point"))
        return
      }

      continuousCaptureEnabled = true
      mainWindow.displayToast(qsTr("Saisie continue activée"))
    }
  }

  Connections {
    target: dashboard

    // property activeLayer from https://api.qfield.org/QField/classQfDashBoard
    function onActiveLayerChanged() {
      if (continuousCaptureEnabled && !isPointLayer(dashboard.activeLayer)) {
        disableContinuousCapture(qsTr("Saisie continue désactivée"))
      }
    }
  }

  Connections {
    target: featureForm
    enabled: canUseContinuousCapture()

    function onAboutToSave() {
      saveStartedInAddMode = featureForm.state === "Add"

      if (saveStartedInAddMode)
        updateFeatureGeometryFromGnss()
    }

    function onConfirmed() {
      nextFeatureLayer = saveStartedInAddMode ? featureModel.currentLayer : null
      saveStartedInAddMode = false
    }

    function onCancelled() {
      saveStartedInAddMode = false
      nextFeatureLayer = null
    }
  }

  Connections {
    target: featureFormDrawer

    function onClosed() {
      const layer = nextFeatureLayer
      nextFeatureLayer = null
      saveStartedInAddMode = false

      if (!continuousCaptureEnabled || !layer)
        return

      Qt.callLater(function() {
        createEmptyFeature(layer)
      })
    }
  }
}
