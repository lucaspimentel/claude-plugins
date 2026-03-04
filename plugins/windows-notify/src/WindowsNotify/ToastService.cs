using Microsoft.Toolkit.Uwp.Notifications;

namespace WindowsNotify;

internal static class ToastService
{
    public static void ShowToast(string title, string message)
    {
        new ToastContentBuilder()
            .AddText(title)
            .AddText(message)
            .Show();
    }
}
