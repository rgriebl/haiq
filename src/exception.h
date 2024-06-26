// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2017-2024 Robert Griebl

#pragma once

#include <QString>
#include <QDir>
#include <QByteArray>
#include <QScopedPointer>
#include <QException>

#include <exception>

QT_FORWARD_DECLARE_CLASS(QFile)

class Exception : public QException
{
public:
    explicit Exception(const char *errorString) Q_DECL_NOEXCEPT;
    explicit Exception(const QString &errorString) Q_DECL_NOEXCEPT;
    explicit Exception(int _errno, const char *errorString) Q_DECL_NOEXCEPT;
    explicit Exception(const QFile &file, const char *errorString) Q_DECL_NOEXCEPT;

    Exception(const Exception &copy) Q_DECL_NOEXCEPT;
    Exception(Exception &&move) Q_DECL_NOEXCEPT;

    ~Exception() Q_DECL_NOEXCEPT override;

    QString errorString() const Q_DECL_NOEXCEPT;

    void raise() const override;
    Exception *clone() const Q_DECL_NOEXCEPT override;

    // convenience
    Exception &arg(const QByteArray &fileName) Q_DECL_NOEXCEPT
    {
        m_errorString = m_errorString.arg(QString::fromLocal8Bit(fileName));
        return *this;
    }
    Exception &arg(const QDir &dir) Q_DECL_NOEXCEPT
    {
        m_errorString = m_errorString.arg(dir.path());
        return *this;
    }

    template <typename... Ts> Exception &arg(const Ts & ...ts) Q_DECL_NOEXCEPT
    {
        m_errorString = m_errorString.arg(ts...);
        return *this;
    }

    // shouldn't be used, but needed for std::exception compatibility
    const char *what() const Q_DECL_NOEXCEPT override;

protected:
    QString m_errorString;

private:
    mutable QByteArray *m_whatBuffer = nullptr;
};
