using System.Text.Json;
using Microsoft.Toolkit.Uwp.Notifications;

namespace WindowsNotify;

internal static class Program
{
    private static readonly TimeSpan ActivationTimeout = TimeSpan.FromMinutes(5);

    [STAThread]
    static int Main(string[] args)
    {
        // If this process was re-launched by COM for toast activation, just exit.
        if (ToastNotificationManagerCompat.WasCurrentProcessToastActivated())
        {
            return 0;
        }

        // Parse CLI args
        string? title = null;
        string? message = null;
        var force = false;

        for (var i = 0; i < args.Length; i++)
        {
            switch (args[i].ToLowerInvariant())
            {
                case "--force":
                case "-f":
                    force = true;
                    break;
                case "--title":
                case "-t":
                    if (i + 1 < args.Length) title = args[++i];
                    break;
                case "--message":
                case "-m":
                    if (i + 1 < args.Length) message = args[++i];
                    break;
            }
        }

        // If title/message not provided via CLI, try reading JSON from stdin
        if (title == null && message == null && !Console.IsInputRedirected)
        {
            // No piped input and no CLI args — use defaults
        }
        else if (title == null || message == null)
        {
            try
            {
                var json = Console.In.ReadToEnd();
                if (!string.IsNullOrWhiteSpace(json))
                {
                    using var doc = JsonDocument.Parse(json);
                    var root = doc.RootElement;

                    if (title == null && root.TryGetProperty("title", out var titleEl))
                        title = titleEl.GetString();
                    if (message == null && root.TryGetProperty("message", out var messageEl))
                        message = messageEl.GetString();
                }
            }
            catch
            {
                // Fall through with defaults
            }
        }

        title = string.IsNullOrWhiteSpace(title) ? "\U0001f916 Claude Code" : $"\U0001f916 {title}";
        message = string.IsNullOrWhiteSpace(message) ? "Needs your attention" : message;

        // Find the terminal window handle by walking the process tree
        var ancestorHwnd = ProcessTreeWalker.FindAncestorWindowHandle();
        var fgHwnd = NativeMethods.GetForegroundWindow();
        var terminalIsForeground = !force && ancestorHwnd != nint.Zero && ancestorHwnd == fgHwnd;

        // If terminal is already in the foreground, flash the taskbar and show toast
        if (terminalIsForeground)
        {
            NativeMethods.FlashTaskbar(ancestorHwnd);
        }

        // Register click handler before showing the toast
        using var activatedEvent = new ManualResetEventSlim(false);

        if (!terminalIsForeground)
        {
            ToastNotificationManagerCompat.OnActivated += _ =>
            {
                if (ancestorHwnd != nint.Zero)
                {
                    if (NativeMethods.IsIconic(ancestorHwnd))
                    {
                        NativeMethods.ShowWindow(ancestorHwnd, NativeMethods.SW_RESTORE);
                    }

                    NativeMethods.SetForegroundWindow(ancestorHwnd);
                }

                activatedEvent.Set();
            };
        }

        // Show the toast
        ToastService.ShowToast(title, message);

        if (terminalIsForeground)
        {
            return 0;
        }

        // Wait for click or timeout, then exit
        activatedEvent.Wait(ActivationTimeout);

        return 0;
    }
}
