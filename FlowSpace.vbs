Set WshShell = CreateObject("WScript.Shell")

' Start services silently
WshShell.Run "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File ""C:\FlowSpace\start-services-silent.ps1""", 0, True

' Wait a moment for services to start
WScript.Sleep 3000

' Launch FlowSpace app
WshShell.Run """C:\FlowSpace\FlowSpaceApp\client_flutter.exe""", 1, False
