#pragma once

#include <QObject>
#include <QString>
#include <QStringList>
#include <QTimer>
#include <QFileSystemWatcher>

namespace volchay {

class LogReader : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString logContent READ logContent NOTIFY logContentChanged)
    Q_PROPERTY(QString logFilePath READ logFilePath NOTIFY logFilePathChanged)
    Q_PROPERTY(bool autoRefresh READ autoRefresh WRITE setAutoRefresh NOTIFY autoRefreshChanged)

public:
    explicit LogReader(QObject* parent = nullptr);

    QString logContent() const { return m_logContent; }
    QString logFilePath() const { return m_logFilePath; }
    bool autoRefresh() const { return m_autoRefresh; }
    void setAutoRefresh(bool enabled);

    Q_INVOKABLE void refresh();
    Q_INVOKABLE void clear();
    Q_INVOKABLE QString filterByLevel(const QString& level);
    Q_INVOKABLE QStringList getAvailableLogFiles();
    Q_INVOKABLE void loadLogFile(const QString& filePath);

signals:
    void logContentChanged();
    void logFilePathChanged();
    void autoRefreshChanged();
    void errorOccurred(const QString& message);

private slots:
    void onFileChanged(const QString& path);
    void onAutoRefreshTimer();

private:
    void loadCurrentLog();
    void setupWatcher();

    QString m_logContent;
    QString m_logFilePath;
    QString m_logsDir;
    bool m_autoRefresh = true;
    QTimer* m_refreshTimer;
    QFileSystemWatcher* m_fileWatcher;
};

} // namespace volchay
