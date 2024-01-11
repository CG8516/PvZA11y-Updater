using System.Diagnostics;
using System.IO;

namespace PvZA11y_Updater
{
    internal class Program
    {
        static void Main(string[] args)
        {
            string ps1Path = Directory.GetCurrentDirectory() + "\\updater.ps1";
            File.WriteAllBytes(ps1Path, Properties.Resources.update);

            var startInfo = new ProcessStartInfo()
            {
                FileName = "powershell.exe",
                Arguments = $"-NoProfile -ExecutionPolicy Bypass -File \"{ps1Path}\"",
                UseShellExecute = false
            };
            Process.Start(startInfo);
        }
    }
}
