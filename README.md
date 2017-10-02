# PanoController-iOS
iOS PanoController App

# Fully functional configuration and control of the Pano Platform over BLE.

- All the menu functions were migrated into app
  - Focal Length, Shutter, Aspect Ratio, pre- and post- shutter delay, multi-shot mode, aspect ratio
  - Pano horizontal and vertical size
- Start button starts the pano after setting up an initial position.
- Cancel function ends the pano
- Pause function enters manual mode:
  - Shutter can be triggered manually with auto advance to next position
  - Platform can be repositioned in all four directions respecting original grid alignment
- Status screen shows all the information in the Arduino OLED display

Needs https://github.com/laurb9/PanoController-Arduino 2.1
