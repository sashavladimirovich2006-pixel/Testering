#include "LogReader.h"
#include "Logger.h"

#include <QFile>
#include <QTextStream>
#include <QDir>
#include <QStandardPaths>
#include <QFileInfo>

namespace volchay {

LogReader::LogReader(QObject* parent)
    : QObject(parent)
    , m_refreshTimer(new QTimer(this))
    , m_fileWatcher(new QFileSystemWatcher(this))
{
    // Определяем путь к логам (тот же, что использует Logger)
    QString appDataDir = QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation);
    m_logsDir = appDataDir + QStringLiteral("/logs");

    // Текущий лог-файл
    m_logFilePath = Logger::instance().currentLogFile();

    // Автообновление каждые 2 секунды
    m_refreshTimer->setInterval(2000);
    connect(m_refreshTimer, &QTimer::timeout, this, &LogReader::onAutoRefreshTimer);

    // Следим за изменениями файла
    connect(m_fileWatcher, &QFileSystemWatcher::fileChanged,
            this, &LogReader::onFileChanged);

    setupWatcher();
    loadCurrentLog();

    if (m_autoRefresh) {
        m_refreshTimer->start();
    }
}

void LogReader::setAutoRefresh(bool enabled) {
    if (m_autoRefresh == enabled) return;
    m_autoRefresh = enabled;

    if (enabled) {
        m_refreshTimer->start();
    } else {
        m_refreshTimer->stop();
    }

    emit autoRefreshChanged();
}

void LogReader::refresh() {
    loadCurrentLog();
}

void LogReader::clear() {
    m_logContent.clear();
    emit logContentChanged();
}

QString LogReader::filterByLevel(const QString& level) {
    QStringList lines = m_logContent.split('\n');
    QStringList filtered;

    QString levelTag = QString("[%1]").arg(level.toUpper());

    for (const QString& line : lines) {
        if (line.contains(levelTag) || line.startsWith("-----")) {
            filtered.append(line);
        }
    }

    return filtered.join('\n');
}

QStringList LogReader::getAvailableLogFiles() {
    QDir logsDir(m_logsDir);
    if (!logsDir.exists()) {
        return QStringList();
    }

    QStringList filters;
    filters << "volchay-*.log";

    QFileInfoList fileList = logsDir.entryInfoList(filters, QDir::Files, QDir::Time);
    QStringList result;

    for (const QFileInfo& fileInfo : fileList) {
        result.append(fileInfo.absoluteFilePath());
    }

    return result;
}

void LogReader::loadLogFile(const QString& filePath) {
    if (filePath.isEmpty()) return;

    m_logFilePath = filePath;
    emit logFilePathChanged();

    // Обновляем watcher
    setupWatcher();
    loadCurrentLog();
}

void LogReader::onFileChanged(const QString& path) {
    Q_UNUSED(path)
    // Файл изменился - перечитываем
    loadCurrentLog();

    // QFileSystemWatcher иногда перестаёт следить после изменения,
    // поэтому переподключаем
    setupWatcher();
}

void LogReader::onAutoRefreshTimer() {
    if (m_autoRefresh) {
        loadCurrentLog();
    }
}

void LogReader::loadCurrentLog() {
    QFile file(m_logFilePath);

    if (!file.exists()) {
        m_logContent = QString("Лог-файл не найден: %1").arg(m_logFilePath);
        emit logContentChanged();
        return;
    }

    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        m_logContent = QString("Не удалось открыть лог-файл: %1").arg(file.errorString());
        emit logContentChanged();
        emit errorOccurred(QString("Ошибка чтения лога: %1").arg(file.errorString()));
        return;
    }

    QTextStream in(&file);
    in.setEncoding(QStringConverter::Utf8);

    // Читаем последние 5000 строк (чтобы не перегружать UI)
    QStringList allLines;
    while (!in.atEnd()) {
        allLines.append(in.readLine());
    }

    // Берём последние 5000 строк
    int startLine = qMax(0, allLines.size() - 5000);
    QStringList recentLines = allLines.mid(startLine);

    m_logContent = recentLines.join('\n');

    file.close();
    emit logContentChanged();
}

void LogReader::setupWatcher() {
    // Удаляем старые пути
    QStringList watched = m_fileWatcher->files();
    if (!watched.isEmpty()) {
        m_fileWatcher->removePaths(watched);
    }

    // Добавляем текущий файл
    if (QFile::exists(m_logFilePath)) {
        m_fileWatcher->addPath(m_logFilePath);
    }
}

} // namespace volchay
