import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: "#0f111a"

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#0f111a" }
            GradientStop { position: 1.0; color: "#1a2740" }
        }
        opacity: 0.95
    }

    ColumnLayout {
        anchors.centerIn: parent
        width: 420
        spacing: 14

        Label {
            text: "DWM Login"
            color: "#e5e9f0"
            font.pixelSize: 34
            horizontalAlignment: Text.AlignHCenter
            Layout.alignment: Qt.AlignHCenter
        }

        Label {
            text: sddm.hostName
            color: "#8aa2c8"
            font.pixelSize: 14
            horizontalAlignment: Text.AlignHCenter
            Layout.alignment: Qt.AlignHCenter
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: 8
            radius: 10
            color: "#151a26"
            border.color: "#4c78c2"
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                ComboBox {
                    id: userCombo
                    model: userModel
                    textRole: "name"
                    Layout.fillWidth: true
                }

                TextField {
                    id: password
                    echoMode: TextInput.Password
                    placeholderText: "Password"
                    Layout.fillWidth: true
                    focus: true
                    onAccepted: loginButton.clicked()
                }

                RowLayout {
                    Layout.fillWidth: true

                    ComboBox {
                        id: sessionCombo
                        model: sessionModel
                        textRole: "name"
                        Layout.fillWidth: true
                    }

                    Button {
                        id: loginButton
                        text: "Login"
                        onClicked: {
                            sddm.login(userCombo.currentText, password.text, sessionCombo.currentIndex)
                        }
                    }
                }

                Label {
                    id: infoLabel
                    text: ""
                    color: "#ff7b7b"
                    font.pixelSize: 12
                }
            }
        }
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            infoLabel.text = "Login failed"
            password.text = ""
            password.forceActiveFocus()
        }
    }
}
