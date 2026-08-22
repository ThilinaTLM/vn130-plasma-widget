/*
 * SPDX-License-Identifier: MIT
 * A small Plasma 6 applet for working around VN130 connection timeouts.
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

import org.kde.bluezqt as BluezQt
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: root

    readonly property string deviceAddress: "AC:EC:8A:52:BB:46"
    readonly property int maximumAttempts: 2

    property var adapter: BluezQt.Manager.usableAdapter
    property var device: BluezQt.Manager.deviceForAddress(deviceAddress)
    property string phase: "idle"
    property string message: "Ready"
    property int attempt: 0
    property bool busy: false
    property bool cancelled: false

    readonly property bool adapterPowered: adapter !== null && adapter.powered
    readonly property bool deviceAvailable: device !== null
    readonly property bool deviceConnected: deviceAvailable && device.connected
    readonly property string stateText: {
        if (busy) {
            return message;
        }
        if (phase === "failed") {
            return message;
        }
        if (!adapterPowered) {
            return "Bluetooth is off";
        }
        if (!deviceAvailable) {
            return "VN130 is unavailable";
        }
        if (deviceConnected) {
            return "VN130 is connected";
        }
        return "VN130 is disconnected";
    }

    function refreshObjects() {
        const usable = BluezQt.Manager.usableAdapter;
        // usableAdapter becomes null while the adapter is powered off. Keep
        // using the first physical adapter so the workflow can power it on.
        adapter = usable !== null
            ? usable
            : (BluezQt.Manager.adapters.length > 0 ? BluezQt.Manager.adapters[0] : null);
        device = BluezQt.Manager.deviceForAddress(deviceAddress);
    }

    function advancePowerTransition() {
        if (phase === "poweringOff" && !adapterPowered) {
            adapterPoweredOff();
        } else if (phase === "poweringOn" && adapterPowered) {
            adapterPoweredOn();
        }
    }

    function stopTimers() {
        transitionTimer.stop();
        operationWatchdog.stop();
        connectionTimeout.stop();
        verificationTimer.stop();
    }

    function beginReconnect() {
        if (busy) {
            return;
        }

        refreshObjects();
        if (adapter === null) {
            fail("No usable Bluetooth adapter was found");
            return;
        }

        stopTimers();
        cancelled = false;
        busy = true;
        attempt = 1;
        resetAdapter();
    }

    function resetAdapter() {
        if (cancelled) {
            finishCancelled();
            return;
        }

        refreshObjects();
        if (adapter === null) {
            fail("Bluetooth adapter disappeared");
            return;
        }

        phase = "poweringOff";
        message = "Attempt " + attempt + ": turning Bluetooth off…";
        operationWatchdog.interval = 10000;
        operationWatchdog.restart();

        if (!adapter.powered) {
            adapterPoweredOff();
        } else {
            adapter.powered = false;
        }
    }

    function adapterPoweredOff() {
        if (phase !== "poweringOff") {
            return;
        }
        operationWatchdog.stop();
        phase = "offDelay";
        message = "Bluetooth is off; waiting…";
        transitionTimer.interval = 2000;
        transitionTimer.action = "powerOn";
        transitionTimer.restart();
    }

    function powerAdapterOn() {
        if (cancelled) {
            finishCancelled();
            return;
        }

        refreshObjects();
        if (adapter === null) {
            fail("Bluetooth adapter is unavailable");
            return;
        }

        phase = "poweringOn";
        message = "Turning Bluetooth on…";
        operationWatchdog.interval = 10000;
        operationWatchdog.restart();

        if (adapter.powered) {
            adapterPoweredOn();
        } else {
            adapter.powered = true;
        }
    }

    function adapterPoweredOn() {
        if (phase !== "poweringOn") {
            return;
        }
        operationWatchdog.stop();
        phase = "onDelay";
        message = "Bluetooth is on; preparing VN130…";
        transitionTimer.interval = 2500;
        transitionTimer.action = "connect";
        transitionTimer.restart();
    }

    function connectDevice() {
        if (cancelled) {
            finishCancelled();
            return;
        }

        refreshObjects();
        if (device === null) {
            retryOrFail("VN130 is not known to BlueZ");
            return;
        }

        phase = "connecting";
        message = "Attempt " + attempt + ": connecting VN130…";
        connectionTimeout.interval = 38000;
        connectionTimeout.restart();
        device.connectToDevice();
    }

    function beginVerification() {
        if (!busy || (phase !== "connecting" && phase !== "verifying")) {
            return;
        }
        phase = "verifying";
        message = "VN130 connected; verifying stability…";
        // The observed faulty connection drops after roughly 28 seconds.
        verificationTimer.interval = 32000;
        verificationTimer.restart();
    }

    function connectionDropped() {
        if (!busy || (phase !== "connecting" && phase !== "verifying")) {
            return;
        }
        verificationTimer.stop();
        connectionTimeout.stop();
        retryOrFail("VN130 disconnected during authentication");
    }

    function retryOrFail(reason) {
        stopTimers();
        if (cancelled) {
            finishCancelled();
            return;
        }

        if (attempt < maximumAttempts) {
            ++attempt;
            phase = "retryDelay";
            message = reason + "; resetting and retrying…";
            transitionTimer.interval = 2000;
            transitionTimer.action = "reset";
            transitionTimer.restart();
        } else {
            fail(reason + " after " + maximumAttempts + " attempts");
        }
    }

    function succeed() {
        stopTimers();
        busy = false;
        phase = "connected";
        message = "VN130 connected successfully";
    }

    function fail(reason) {
        stopTimers();
        busy = false;
        phase = "failed";
        message = reason;
    }

    function cancel() {
        if (!busy) {
            return;
        }
        cancelled = true;
        finishCancelled();
    }

    function finishCancelled() {
        stopTimers();
        busy = false;
        phase = "idle";
        message = "Operation cancelled";
        refreshObjects();
    }

    function disconnectDevice() {
        refreshObjects();
        if (device !== null && device.connected) {
            device.disconnectFromDevice();
            phase = "idle";
            message = "Disconnecting VN130…";
        }
    }

    Plasmoid.title: "VN130 Controller"
    Plasmoid.icon: deviceConnected ? "audio-headset-bluetooth" : "bluetooth"
    Plasmoid.status: deviceConnected || busy ? PlasmaCore.Types.ActiveStatus : PlasmaCore.Types.PassiveStatus
    toolTipSubText: stateText

    compactRepresentation: MouseArea {
        id: compact
        hoverEnabled: true

        onClicked: {
            if (!root.busy && !root.deviceConnected) {
                root.beginReconnect();
            } else {
                root.expanded = !root.expanded;
            }
        }

        Kirigami.Icon {
            anchors.fill: parent
            source: Plasmoid.icon
            opacity: root.adapterPowered ? 1.0 : 0.45
        }

        QQC2.BusyIndicator {
            anchors.centerIn: parent
            width: parent.width * 0.62
            height: width
            running: root.busy
            visible: running
        }
    }

    fullRepresentation: Item {
        implicitWidth: Kirigami.Units.gridUnit * 20
        implicitHeight: Kirigami.Units.gridUnit * 22

        ColumnLayout {
            id: content
            anchors.fill: parent
            anchors.margins: Kirigami.Units.largeSpacing * 2
            spacing: Kirigami.Units.largeSpacing

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Icon {
                    Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                    Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                    source: "audio-headset-bluetooth"
                }

                Kirigami.Heading {
                    Layout.fillWidth: true
                    level: 2
                    text: "VN130 Controller"
                }
            }

            PlasmaComponents3.Button {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: Kirigami.Units.gridUnit * 14
                Layout.preferredHeight: Kirigami.Units.gridUnit * 3.4
                text: root.busy
                    ? "Working…"
                    : (root.deviceConnected ? "Reconnect" : "Connect")
                enabled: !root.busy
                onClicked: root.beginReconnect()
            }

            PlasmaComponents3.Label {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: root.stateText
                wrapMode: Text.Wrap
                font.bold: root.deviceConnected
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Icon {
                    Layout.preferredWidth: Kirigami.Units.iconSizes.small
                    Layout.preferredHeight: Kirigami.Units.iconSizes.small
                    source: "dialog-information"
                    opacity: 0.75
                }

                PlasmaComponents3.Label {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: "Resetting Bluetooth briefly disconnects\nevery Bluetooth device."
                    opacity: 0.75
                }
            }

            Item {
                Layout.fillHeight: true
                Layout.minimumHeight: Kirigami.Units.largeSpacing
            }

            Kirigami.Separator {
                Layout.fillWidth: true
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: Kirigami.Units.largeSpacing
                rowSpacing: Kirigami.Units.smallSpacing

                PlasmaComponents3.Label { text: "Device"; opacity: 0.65 }
                PlasmaComponents3.Label { text: "VN130" }
                PlasmaComponents3.Label { text: "Bluetooth"; opacity: 0.65 }
                PlasmaComponents3.Label { text: root.adapterPowered ? "On" : "Off" }
                PlasmaComponents3.Label { text: "Connection"; opacity: 0.65 }
                PlasmaComponents3.Label { text: root.deviceConnected ? "Connected" : "Disconnected" }
                PlasmaComponents3.Label { text: "Attempt"; opacity: 0.65; visible: root.busy }
                PlasmaComponents3.Label { text: root.attempt + " of " + root.maximumAttempts; visible: root.busy }
            }

            RowLayout {
                Layout.fillWidth: true
                visible: root.busy || root.deviceConnected

                Item { Layout.fillWidth: true }

                PlasmaComponents3.Button {
                    flat: true
                    text: root.busy ? "Cancel" : "Disconnect"
                    icon.name: root.busy ? "dialog-cancel" : "network-disconnect"
                    onClicked: root.busy ? root.cancel() : root.disconnectDevice()
                }
            }
        }
    }

    // BluezQt swaps usableAdapter to null while Bluetooth is off. Polling the
    // retained physical adapter makes power transitions reliable across that
    // object change, while property-change signals still handle the fast path.
    Timer {
        id: statePoll
        interval: 250
        repeat: true
        running: root.busy
        onTriggered: {
            root.refreshObjects();
            root.advancePowerTransition();
        }
    }

    Timer {
        id: transitionTimer
        property string action: ""
        repeat: false
        onTriggered: {
            if (action === "powerOn") {
                root.powerAdapterOn();
            } else if (action === "connect") {
                root.connectDevice();
            } else if (action === "reset") {
                root.resetAdapter();
            }
        }
    }

    Timer {
        id: operationWatchdog
        repeat: false
        onTriggered: root.retryOrFail("Bluetooth power transition timed out")
    }

    Timer {
        id: connectionTimeout
        repeat: false
        onTriggered: root.retryOrFail("VN130 connection timed out")
    }

    Timer {
        id: verificationTimer
        repeat: false
        onTriggered: {
            root.refreshObjects();
            if (root.deviceConnected) {
                root.succeed();
            } else {
                root.retryOrFail("VN130 did not remain connected");
            }
        }
    }

    Connections {
        target: BluezQt.Manager

        function onUsableAdapterChanged() {
            root.refreshObjects();
        }


        function onDevicesChanged() {
            root.refreshObjects();
        }

        function onDeviceAdded() {
            root.refreshObjects();
        }

        function onDeviceRemoved() {
            root.refreshObjects();
        }
    }

    Connections {
        target: root.adapter
        ignoreUnknownSignals: true

        function onPoweredChanged() {
            root.refreshObjects();
            root.advancePowerTransition();
            if (!root.adapterPowered) {
                root.adapterPoweredOff();
            } else {
                root.adapterPoweredOn();
            }
        }
    }

    Connections {
        target: root.device
        ignoreUnknownSignals: true

        function onConnectedChanged() {
            root.refreshObjects();
            if (root.deviceConnected) {
                root.beginVerification();
            } else {
                root.connectionDropped();
            }
        }
    }

    Component.onCompleted: {
        refreshObjects();
        if (deviceConnected) {
            phase = "connected";
            message = "VN130 is connected";
        }
    }
}
