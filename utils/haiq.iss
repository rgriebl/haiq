﻿#ifndef SOURCE_DIR
#define SOURCE_DIR "."
#endif

#define ApplicationVersionFull GetVersionNumbersString(SOURCE_DIR + "\HAiQ.exe")
#define ApplicationVersion RemoveFileExt(ApplicationVersionFull)
#define ApplicationPublisher GetFileCompany(SOURCE_DIR + "\HAiQ.exe")


[Setup]
AppName=HAiQ
AppVersion={#ApplicationVersion}
AppPublisher={#ApplicationPublisher}
AppPublisherURL={#ApplicationPublisher}
VersionInfoVersion={#ApplicationVersionFull}
DefaultDirName={commonpf}\HAiQ
DefaultGroupName=HAiQ
UninstallDisplayIcon={app}\HAiQ.exe
; Since no icons will be created in "{group}", we do not need the wizard
; to ask for a Start Menu folder name:
DisableProgramGroupPage=yes
DisableReadyPage=yes
DisableWelcomePage=yes
SourceDir={#SOURCE_DIR}
OutputBaseFilename=HAiQ Installer
CloseApplications=yes
RestartApplications=yes

[Languages]
Name: "en"; MessagesFile: "compiler:Default.isl"
Name: "de"; MessagesFile: "compiler:Languages\German.isl"

[Tasks]
Name: "office"; Description: "Add Shortcut for Office UI"; Flags: exclusive

[Files]
Source: "*.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "*.dll"; DestDir: "{app}"; Flags: recursesubdirs ignoreversion
Source: "qmldir"; DestDir: "{app}"; Flags: recursesubdirs ignoreversion
Source: "*.qmltypes"; DestDir: "{app}"; Flags: recursesubdirs ignoreversion
; MSVC
Source: "vc_redist.x86.exe"; DestDir: "{tmp}"; Flags: deleteafterinstall skipifsourcedoesntexist
Source: "vc_redist.x64.exe"; DestDir: "{tmp}"; Flags: deleteafterinstall skipifsourcedoesntexist

[Run]
Filename: "{tmp}\vc_redist.x86.exe"; StatusMsg: "Microsoft C/C++ runtime"; \
    Parameters: "/quiet /norestart"; Flags: waituntilterminated skipifdoesntexist; \
    Check: noMSVCInstalled('x86')
Filename: "{tmp}\vc_redist.x64.exe"; StatusMsg: "Microsoft C/C++ runtime"; \
    Parameters: "/quiet /norestart"; Flags: waituntilterminated skipifdoesntexist; \
    Check: noMSVCInstalled('x64')

[Icons]
Name: "{commonprograms}\Büro - HAiQ"; Filename: "{app}\HAiQ.exe"; Parameters: "--variant office"; Tasks: office
Name: "{commonstartup}\Büro - HAiQ"; Filename: "{app}\HAiQ.exe"; Parameters: "--variant office"; Tasks: office


[Code]
function noMSVCInstalled(Arch: String): Boolean;
var
    Version: Int64;
begin
    Version := PackVersionComponents(14, 29, 30037, 0);
    if Arch = 'x86' then
        Result := not IsMsiProductInstalled('{65E5BD06-6392-3027-8C26-853107D3CF1A}', Version)
    else if Arch = 'x64' then
        Result := not IsMsiProductInstalled('{36F68A90-239C-34DF-B58C-64B30153CE35}', Version)
    else
        Result := True;
end;
