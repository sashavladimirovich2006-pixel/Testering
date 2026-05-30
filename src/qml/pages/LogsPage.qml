import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    color: Theme.background

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 28
        spacing: 20

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            Text {
                text: qsTr("Логи программы")
                color: Theme.text
                font.pixelSize: 26
                font.bold: true
            }

            Item { Layout.fillWidth: true }

            // Auto-refresh toggle
            RowLayout {
                spacing: 8
                Text {
                    text: qsTr("Автообновление")
                    color: Theme.textMuted
                    font.pixelSize: 13
                }
                Switch {
                    checked: LogReader.autoRefresh
                    onToggled: LogReader.autoRefresh = checked
                }
            }

            // Refresh button
            Button {
                text: qsTr("Обновить")
                font.pixelSize: 13
                onClicked: LogReader.refresh()
                background: Rectangle {
                    color: parent.hovered ? Theme.surfaceAlt : Theme.surface
                    border.color: Theme.border
                    border.width: 1
                    radius: 8
                }
                contentItem: Text {
                    text: parent.text
                    color: Theme.text
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font: parent.font
                }
            }

            // Clear button
            Button {
                text: qsTr("Очистить")
                font.pixelSize: 13
                onClicked: logTextArea.text = ""
                background: Rectangle {
                    color: parent.hovered ? Theme.surfaceAlt : Theme.surface
                    border.color: Theme.border
                    border.width: 1
                    radius: 8
                }
                contentItem: Text {
                    text: parent.text
                    color: Theme.text
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font: parent.font
                }
            }
        }

        // Filter bar
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Text {
                text: qsTr("Фильтр:")
                color: Theme.textMuted
                font.pixelSize: 13
            }

            Repeater {
                model: [
                    { label: qsTr("Все"), level: "" },
                    { label: "DEBUG", level: "debug" },
                    { label: "INFO", level: "info" },
                    { label: "WARN", level: "warn" },
                    { label: "ERROR", level: "error" },
                    { label: "FATAL", level: "fatal" }
                ]
                delegate: Button {
                    text: modelData.label
                    font.pixelSize: 12
                    checkable: true
                    checked: index === 0
                    ButtonGroup.group: filterGroup
                    onClicked: {
                        if (modelData.level === "") {
                            logTextArea.text = LogReader.logContent
                        } else {
                            logTextArea.text = LogReader.filterByLevel(modelData.level)
                        }
                    }
                    background: Rectangle {
                        color: parent.checked ? Theme.accent : (parent.hovered ? Theme.surfaceAlt : Theme.surface)
                        border.color: parent.checked ? Theme.accent : Theme.border
                        border.width: 1
                        radius: 6
                    }
                    contentItem: Text {
                        text: parent.text
                        color: parent.checked ? "#FFFFFF" : Theme.text
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font: parent.font
                    }
                }
            }

            ButtonGroup { id: filterGroup }

            Item { Layout.fillWidth: true }

            // Search field
            TextField {
                id: searchField
                Layout.preferredWidth: 240
                placeholderText: qsTr("Поиск...")
                font.pixelSize: 13
                color: Theme.text
                background: Rectangle {
                    color: Theme.surface
                    border.color: searchField.activeFocus ? Theme.accent : Theme.border
                    border.width: 1
                    radius: 8
                }
                onTextChanged: {
                    if (text.length > 0) {
                        highlightSearch(text)
                    }
                }
            }
        }

        // Log file selector
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Text {
                text: qsTr("Файл лога:")
                color: Theme.textMuted
                font.pixelSize: 13
            }

            ComboBox {
                id: logFileCombo
                Layout.preferredWidth: 400
                model: LogReader.getAvailableLogFiles()
                currentIndex: 0
                font.pixelSize: 12
                onActivated: function(index) {
                    if (index >= 0 && index < model.length) {
                        LogReader.loadLogFile(model[index])
                    }
                }
                background: Rectangle {
                    color: Theme.surface
                    border.color: logFileCombo.activeFocus ? Theme.accent : Theme.border
                    border.width: 1
                    radius: 8
                }
                contentItem: Text {
                    text: {
                        if (logFileCombo.currentIndex >= 0 && logFileCombo.currentIndex < logFileCombo.model.length) {
                            var path = logFileCombo.model[logFileCombo.currentIndex]
                            return path.substring(path.lastIndexOf("/") + 1)
                        }
                        return ""
                    }
                    color: Theme.text
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideMiddle
                    font: logFileCombo.font
                    leftPadding: 12
                }
            }

            Text {
                text: qsTr("Путь: ") + LogReader.logFilePath
                color: Theme.textMuted
                font.pixelSize: 11
                elide: Text.ElideMiddle
                Layout.fillWidth: true
            }
        }

        // Log content area
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Theme.surface
            border.color: Theme.border
            border.width: 1
            radius: 12

            ScrollView {
                anchors.fill: parent
                anchors.margins: 2
                clip: true

                TextArea {
                    id: logTextArea
                    readOnly: true
                    wrapMode: TextArea.NoWrap
                    font.family: "Consolas, Courier New, monospace"
                    font.pixelSize: 11
                    color: Theme.text
                    selectByMouse: true
                    selectByKeyboard: true
                    background: Rectangle {
                        color: "#0A0A0A"
                        radius: 10
                    }

                    text: LogReader.logContent

                    // Syntax highlighting через textFormat
                    textFormat: TextEdit.PlainText

                    Connections {
                        target: LogReader
                        function onLogContentChanged() {
                            // Обновляем текст и прокручиваем вниз
                            logTextArea.text = LogReader.logContent
                            logTextArea.cursorPosition = logTextArea.length
                        }
                    }
                }
            }
        }

        // Footer info
        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            Rectangle {
                width: 8; height: 8; radius: 4
                color: LogReader.autoRefresh ? Theme.accent : Theme.textMuted
            }

            Text {
                text: LogReader.autoRefresh ? qsTr("Автообновление активно (каждые 2 сек)")
                                            : qsTr("Автообновление отключено")
                color: Theme.textMuted
                font.pixelSize: 12
            }

            Item { Layout.fillWidth: true }

            Text {
                text: qsTr("Строк: ") + logTextArea.lineCount
                color: Theme.textMuted
                font.pixelSize: 12
            }
        }
    }

    function highlightSearch(query) {
        // Простой поиск - прокручиваем к первому вхождению
        var content = logTextArea.text
        var index = content.indexOf(query, logTextArea.cursorPosition)
        if (index === -1) {
            index = content.indexOf(query, 0)
        }
        if (index !== -1) {
            logTextArea.cursorPosition = index
            logTextArea.select(index, index + query.length)
        }
    }
}
