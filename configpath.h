#ifndef CONFIGPATH_H
#define CONFIGPATH_H

#include <QDir>
#include <QString>

namespace ConfigPath
{

inline QString normalize(QString path)
{
    // Configuration files are shared across platforms. Accept both Windows
    // backslashes and Unix-style forward slashes regardless of the host OS.
    path.replace(QLatin1Char('\\'), QLatin1Char('/'));
    return QDir::cleanPath(path);
}

inline QString resolve(const QDir& baseDirectory, const QString& path)
{
    const QString normalizedPath = normalize(path);
    if (QDir::isAbsolutePath(normalizedPath))
        return normalizedPath;

    return QDir::cleanPath(baseDirectory.absoluteFilePath(normalizedPath));
}

}

#endif // CONFIGPATH_H
