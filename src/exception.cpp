/* Copyright (C) 2017-2022 Robert Griebl. All rights reserved.
**
** This file is part of HAiQ.
**
** This file may be distributed and/or modified under the terms of the GNU
** General Public License version 2 as published by the Free Software Foundation
** and appearing in the file LICENSE.GPL included in the packaging of this file.
**
** This file is provided AS IS with NO WARRANTY OF ANY KIND, INCLUDING THE
** WARRANTY OF DESIGN, MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
**
** See http://fsf.org/licensing/licenses/gpl.html for GPL licensing information.
*/
#include <QFile>
#include <errno.h>

#include "exception.h"

Exception::Exception(const char *errorString) Q_DECL_NOEXCEPT
    : m_errorString(errorString ? QLatin1String(errorString) : QString())
{ }

Exception::Exception(const QString &errorString) Q_DECL_NOEXCEPT
    : m_errorString(errorString)
{ }

Exception::Exception(int _errno, const char *errorString) Q_DECL_NOEXCEPT
    : m_errorString(QLatin1String(errorString) + QStringLiteral(": ") + QString::fromLocal8Bit(strerror(_errno)))
{ }

Exception::Exception(const QFile &file, const char *errorString) Q_DECL_NOEXCEPT
    : m_errorString(QLatin1String(errorString) + QStringLiteral(" (") + file.fileName() + QStringLiteral("): ") + file.errorString())
{ }

Exception::Exception(const Exception &copy) Q_DECL_NOEXCEPT
    : m_errorString(copy.m_errorString)
{ }

Exception::Exception(Exception &&move) Q_DECL_NOEXCEPT
    : m_errorString(move.m_errorString)
{
    qSwap(m_whatBuffer, move.m_whatBuffer);
}

Exception::~Exception() Q_DECL_NOEXCEPT
{
    delete m_whatBuffer;
}

QString Exception::errorString() const Q_DECL_NOEXCEPT
{
    return m_errorString;
}

void Exception::raise() const
{
    throw *this;
}

Exception *Exception::clone() const Q_DECL_NOEXCEPT
{
    return new Exception(*this);
}

const char *Exception::what() const Q_DECL_NOEXCEPT
{
    if (!m_whatBuffer)
        m_whatBuffer = new QByteArray;
    *m_whatBuffer = m_errorString.toLocal8Bit();
    return m_whatBuffer->constData();
}
