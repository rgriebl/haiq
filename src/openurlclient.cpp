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
#include <jni.h>
#include <QVariant>
#include <QUrl>
#include <QDebug>

#include "openurlclient.h"

OpenUrlClient *OpenUrlClient::s_instance = nullptr;

OpenUrlClient::OpenUrlClient(QObject *parent)
    : QObject(parent)
{ }

OpenUrlClient *OpenUrlClient::instance()
{
    if (!s_instance)
        s_instance = new OpenUrlClient;
    return s_instance;
}

#ifdef __cplusplus
extern "C" {
#endif

JNIEXPORT void JNICALL
Java_org_griebl_haiq_OpenUrlClient_setUrl(JNIEnv *env, jobject /*obj*/, jstring jurl)
{
    auto urlStr = env->GetStringUTFChars(jurl, nullptr);
    QUrl url = QString::fromUtf8(urlStr);

    QString command = url.host();
    QStringList parameters = url.path().split("/").mid(1);

    qWarning() << "STARTED BY COMMAND:" << command << ", PARAMETERS:" << parameters;
    emit OpenUrlClient::instance()->commandReceived(command, parameters);

    env->ReleaseStringUTFChars(jurl, urlStr);
}

#ifdef __cplusplus
}
#endif
