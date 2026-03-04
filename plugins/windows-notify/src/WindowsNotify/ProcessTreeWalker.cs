using System.Diagnostics;

namespace WindowsNotify;

internal static class ProcessTreeWalker
{
    /// <summary>
    /// Walk from the current process up through parent processes,
    /// returning the MainWindowHandle of the first ancestor that has a visible window.
    /// </summary>
    public static nint FindAncestorWindowHandle()
    {
        var pid = Environment.ProcessId;

        while (pid > 0)
        {
            try
            {
                var proc = Process.GetProcessById(pid);
                if (proc.MainWindowHandle != nint.Zero)
                {
                    return proc.MainWindowHandle;
                }
            }
            catch
            {
                break;
            }

            var parentPid = GetParentProcessId(pid);
            if (parentPid <= 0 || parentPid == pid)
            {
                break;
            }

            pid = parentPid;
        }

        return nint.Zero;
    }

    private static int GetParentProcessId(int pid)
    {
        var handle = NativeMethods.OpenProcess(NativeMethods.PROCESS_QUERY_LIMITED_INFORMATION, false, pid);
        if (handle == nint.Zero)
        {
            return -1;
        }

        try
        {
            var pbi = new NativeMethods.PROCESS_BASIC_INFORMATION();
            var status = NativeMethods.NtQueryInformationProcess(
                handle,
                0, // ProcessBasicInformation
                ref pbi,
                System.Runtime.InteropServices.Marshal.SizeOf(pbi),
                out _);

            return status == 0 ? (int)pbi.InheritedFromUniqueProcessId : -1;
        }
        finally
        {
            NativeMethods.CloseHandle(handle);
        }
    }
}
