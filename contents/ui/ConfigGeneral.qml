/*
 * SPDX-License-Identifier: MIT
 */

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami

KCM.SimpleKCM {
    id: configPage

    property alias cfg_deviceName: deviceNameField.text
    property string cfg_deviceAddress
    property alias cfg_maximumAttempts: maximumAttemptsSpinBox.value
    property alias cfg_powerOffDelayMs: powerOffDelaySpinBox.value
    property alias cfg_powerOnDelayMs: powerOnDelaySpinBox.value
    property alias cfg_connectionTimeoutMs: connectionTimeoutSpinBox.value
    property alias cfg_verificationDurationMs: verificationDurationSpinBox.value

    function secondsText(value, locale) {
        const decimals = value % 1000 === 0 ? 0 : 1;
        return Number(value / 1000).toLocaleString(locale, "f", decimals) + " s";
    }

    onCfg_deviceAddressChanged: {
        if (!deviceAddressField.activeFocus) {
            deviceAddressField.text = cfg_deviceAddress;
        }
    }

    Kirigami.FormLayout {
        id: formLayout

        // Keep controls clear of the overlaid vertical scrollbar and allow
        // long explanatory text to wrap inside the dialog viewport.
        Layout.fillWidth: true
        Layout.rightMargin: Kirigami.Units.largeSpacing * 2

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Device"
        }

        QQC2.TextField {
            id: deviceNameField

            Kirigami.FormData.label: "Device name:"
            Layout.fillWidth: true
            placeholderText: "VN130"
        }

        ColumnLayout {
            Kirigami.FormData.label: "Bluetooth address:"
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            QQC2.TextField {
                id: deviceAddressField

                Layout.fillWidth: true
                placeholderText: "XX:XX:XX:XX:XX:XX"
                inputMethodHints: Qt.ImhUppercaseOnly | Qt.ImhNoPredictiveText
                validator: RegularExpressionValidator {
                    regularExpression: /^[0-9A-Fa-f]{2}(:[0-9A-Fa-f]{2}){5}$/
                }

                onTextEdited: {
                    const normalizedAddress = text.trim().toUpperCase();
                    if (/^[0-9A-F]{2}(:[0-9A-F]{2}){5}$/.test(normalizedAddress)) {
                        configPage.cfg_deviceAddress = normalizedAddress;
                    }
                }
                onEditingFinished: {
                    if (acceptableInput) {
                        text = text.trim().toUpperCase();
                    } else {
                        text = configPage.cfg_deviceAddress;
                    }
                }

                Component.onCompleted: text = configPage.cfg_deviceAddress
            }

            QQC2.Label {
                Layout.fillWidth: true
                visible: deviceAddressField.text.length > 0 && !deviceAddressField.acceptableInput
                text: "Enter an address in the form XX:XX:XX:XX:XX:XX."
                color: Kirigami.Theme.negativeTextColor
                wrapMode: Text.Wrap
            }
        }

        Kirigami.InlineMessage {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            type: Kirigami.MessageType.Information
            text: "The Bluetooth device must already be paired. This widget never creates or removes pairings."
            visible: true
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Recovery"
        }

        QQC2.SpinBox {
            id: maximumAttemptsSpinBox

            Kirigami.FormData.label: "Maximum attempts:"
            from: 1
            to: 10
            stepSize: 1
        }

        QQC2.SpinBox {
            id: powerOffDelaySpinBox

            Kirigami.FormData.label: "Bluetooth-off wait:"
            from: 500
            to: 10000
            stepSize: 500
            textFromValue: (value, locale) => configPage.secondsText(value, locale)
        }

        QQC2.SpinBox {
            id: powerOnDelaySpinBox

            Kirigami.FormData.label: "Bluetooth-on wait:"
            from: 500
            to: 10000
            stepSize: 500
            textFromValue: (value, locale) => configPage.secondsText(value, locale)
        }

        QQC2.SpinBox {
            id: connectionTimeoutSpinBox

            Kirigami.FormData.label: "Connection timeout:"
            from: 5000
            to: 120000
            stepSize: 1000
            textFromValue: (value, locale) => configPage.secondsText(value, locale)
        }

        QQC2.SpinBox {
            id: verificationDurationSpinBox

            Kirigami.FormData.label: "Stability check:"
            from: 5000
            to: 120000
            stepSize: 1000
            textFromValue: (value, locale) => configPage.secondsText(value, locale)
        }

        QQC2.Label {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            text: "Each attempt resets the Bluetooth adapter, temporarily disconnecting every Bluetooth device. The stability check waits for delayed authentication failures before reporting success."
            opacity: 0.75
            wrapMode: Text.Wrap
        }
    }
}
