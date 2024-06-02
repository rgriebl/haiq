// Copyright (C) 2017-2024 Robert Griebl
// SPDX-License-Identifier: GPL-3.0-only

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
