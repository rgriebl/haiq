package org.griebl.haiq;

import org.qtproject.qt.android.bindings.QtActivity;
import android.os.*;
import android.content.*;
import android.app.*;

public class OpenUrlClient extends QtActivity
{
    public static native void setUrl(String url);

    @Override
    public void onCreate(Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);
    }

    @Override
    public void onNewIntent(Intent intent)
    {
        super.onNewIntent(intent);
        setIntent(intent);
        String uri = intent.getDataString();
        if (uri != null) {
            setUrl(uri);
        }
    }
}
