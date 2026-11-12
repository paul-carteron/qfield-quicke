# QuickE, the Auto-Reopening Form plugin

The `QuickE` plugin add a continuous capture mode that automatically reopen the current layer feature form. This allow for a rapid and continuous entry workflow !

`QuickE` works only for point features and inserts each new feature at the **current position**.

<p align="center">
  <img src="https://github.com/user-attachments/assets/7c039821-6ee1-48b7-853f-efbff0d1a57d" height="400">
</p>

# How to use QuickE

1. Activate position and select an editable layer;
2. Tap the `QuickE` button in the plugin toolbar to activate continuous capture mode;
3. Add a point and save it, the form will reopens automatically;
4. To stop continuous capture for current layer, simply cancel the form;
5. Tap the `QuickE` button toolbar again if you want to disable continuous capture.

# Details

- When saving a new point, `QuickE` uses the current position and converts it into the layer's CRS;
- After a successful new-point save, `QuickE` opens a new feature form on the same layer;
- Editing an existing point does not change its position or trigger automatic reopening;
- Cancelling the form ends the current entry sequence. `QuickE` remains enabled until you disable it using the toolbar button;
- Switching to a line, polygon or table layer automatically disables `QuickE`;
- If position is inactive or its coordinates are invalid, `QuickE` displays a warning and leaves the geometry unchanged. This warning does not itself block saving.

# Installation

To install the plugin, download the latest release from the [releases page](https://github.com/paul-carteron/qfield-quicke/releases/tag/v1.0.2) and follow the [plugin installation guide](https://docs.qfield.org/how-to/advanced-how-tos/plugins/#application-plugins).
