pragma Singleton
import QtQuick
import Quickshell

// UI state for the bar's popovers (wifi list, battery card). Same open/screen pair
// as the control center: the popover lives on the screen whose chip was clicked.
Singleton {
    id: root

    property string wifiPopupScreen: ""
    property bool wifiPopupOpen: false

    property string batteryPopupScreen: ""
    property bool batteryPopupOpen: false

    function openWifiPopup(screenName) {
        wifiPopupOpen = true;
        wifiPopupScreen = screenName;
        batteryPopupOpen = false;
    }

    function closeWifiPopup() {
        wifiPopupOpen = false;
    }

    function unloadWifiPopup(screenName) {
        if (!wifiPopupOpen && wifiPopupScreen === screenName)
            wifiPopupScreen = "";
    }

    function toggleWifiPopup(screenName) {
        if (wifiPopupOpen && wifiPopupScreen === screenName)
            closeWifiPopup();
        else
            openWifiPopup(screenName);
    }

    function openBatteryPopup(screenName) {
        batteryPopupOpen = true;
        batteryPopupScreen = screenName;
        wifiPopupOpen = false;
    }

    function closeBatteryPopup() {
        batteryPopupOpen = false;
    }

    function unloadBatteryPopup(screenName) {
        if (!batteryPopupOpen && batteryPopupScreen === screenName)
            batteryPopupScreen = "";
    }

    function toggleBatteryPopup(screenName) {
        if (batteryPopupOpen && batteryPopupScreen === screenName)
            closeBatteryPopup();
        else
            openBatteryPopup(screenName);
    }
}
