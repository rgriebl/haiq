// Copyright (C) 2017-2024 Robert Griebl
// SPDX-License-Identifier: GPL-3.0-only

#include <QFile>
#include <QDebug>
#include <QJsonDocument>
#include <QJsonParseError>
#include <QJsonObject>
#include <QJsonArray>
#include <QJsonValue>

#include "exception.h"
#include "configuration.h"


Configuration::Configuration(const QString &configFile,  const QString &variant)
    : m_configFile(configFile)
    , m_variant(variant)
{
    if (configFile.isEmpty())
        qWarning() << "No config file set!";
}

const QStringList &Configuration::possibleVariants() const
{
    return m_possibleVariants;
}

QVariant Configuration::operator[](const char *key) const
{
    return m_map.value(QString::fromLatin1(key));
}

// Qt6 removed v_cast, but the "replacement" QVariant::Private::get is const only
template <typename T> T *v_cast(QVariant::Private *vp)
{
    return static_cast<T *>(const_cast<void *>(vp->storage()));
}


// based on the version in QtApplicationManager, author yours truly
void Configuration::recursiveMergeVariantMap(QVariantMap &into, const QVariantMap &from)
{
    // no auto allowed, since this is a recursive lambda
    std::function<void(QVariantMap *, const QVariantMap &)> recursiveMergeMap =
            [&recursiveMergeMap](QVariantMap *into, const QVariantMap &from) {
        for (auto it = from.constBegin(); it != from.constEnd(); ++it) {
            QVariant fromValue = it.value();
            QVariant &toValue = (*into)[it.key()];

            bool needsMerge = (toValue.typeId() == fromValue.typeId());

            // we're trying not to detach, so we're using v_cast to avoid copies
            if (needsMerge && (toValue.typeId() == QMetaType::QVariantMap))
                recursiveMergeMap(v_cast<QVariantMap>(&toValue.data_ptr()), fromValue.toMap());
            else if (needsMerge && (toValue.typeId() == QMetaType::QVariantList))
                into->insert(it.key(), toValue.toList() + fromValue.toList());
            else if (int(fromValue.typeId()) == QMetaType::Nullptr)
                into->remove(it.key());
            else
                into->insert(it.key(), fromValue);
        }
    };
    recursiveMergeMap(&into, from);
}


void Configuration::parse()
{
    if (m_parsed)
        return;

    auto parseJson = [](const QString &fileName) {
        QFile f(fileName);
        if (!f.open(QFile::ReadOnly))
            throw Exception(f, "Cannot open for reading");

        QJsonParseError parseError;
        QByteArray data = f.readAll();
        const QJsonDocument json = QJsonDocument::fromJson(data, &parseError);
        if (json.isNull()) {
            auto line = data.left(parseError.offset).count('\n') + 1;
            auto lpos = data.lastIndexOf('\n', parseError.offset);
            auto rpos = data.indexOf('\n', parseError.offset);

            if (rpos >= 1 && data.at(rpos - 1) == '\r')
                --rpos;

            throw Exception("Cannot parse \"%1\": %2 at line %3:\n%4\n%5^")
                    .arg(fileName, parseError.errorString()).arg(line)
                    .arg(QString::fromUtf8(data.mid(lpos + 1, rpos - lpos - 1)))
                    .arg(QString(parseError.offset - lpos - 1, QChar(' ')));
        }
        return json;
    };

    QJsonDocument configJson = parseJson(m_configFile);

    if (!configJson.isArray())
        throw Exception("Cannot parse \"%1\": not an array").arg(m_configFile);

    const auto array = configJson.array();
    for (const auto value : array) {
        if (!value.isObject())
            continue;
        const auto object = value.toObject();
        if (object.size() != 1)
            continue;
        auto key = object.constBegin().key();

        if (m_variant.isEmpty()) {
            if (key.contains(u'|'))
                m_possibleVariants.append(key.split(u'|'));
            else if (!key.isEmpty())
                m_possibleVariants.append(key);

            continue;
        }

        bool apply = key.isEmpty();
        if (!apply) {
            const QStringList keyList = key.split(u'|');

            for (const auto &k : keyList) {
                QRegularExpression keyRe { QRegularExpression::wildcardToRegularExpression(k) };
                apply = apply || keyRe.match(m_variant).hasMatch();
            }
        }
        if (apply)
            recursiveMergeVariantMap(m_map, object.constBegin().value().toObject().toVariantMap());
    }
    if (!m_possibleVariants.isEmpty()) {
        for (auto it = m_possibleVariants.begin(); it != m_possibleVariants.end(); ) {
            if (it->isEmpty() || it->contains(u"*"))
                it = m_possibleVariants.erase(it);
            else
                ++it;
        }
        m_possibleVariants.sort();
        m_possibleVariants.removeDuplicates();

        // qWarning() << "Possible Variants:" << *possibleVariants;
    }

    m_parsed = true;
}
