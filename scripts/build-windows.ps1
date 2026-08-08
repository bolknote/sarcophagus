#Requires -Version 5.1

[CmdletBinding()]
param(
    [string]$LoveFile = "",
    [string]$LoveArchive = "",
    [string]$OutputDirectory = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$version = (Get-Content -LiteralPath (Join-Path $projectRoot "version.txt") -Raw).Trim()
$loveVersion = "11.5"
$loveRuntimeUrl = "https://github.com/love2d/love/releases/download/11.5/love-11.5-win64.zip"
$loveRuntimeSha256 = "ba6e56be2685e53c817749c4a5007f51137136fe5a3ab64920508babc2e74369"
$manifestSource = Join-Path $projectRoot "packaging/windows/Sarcophagus.exe.manifest"
$iconSource = Join-Path $projectRoot "packaging/windows/Sarcophagus.ico"

if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
    throw "The Windows package must be built on Windows (PowerShell 5.1 or newer)."
}

if ([string]::IsNullOrWhiteSpace($LoveFile)) {
    $LoveFile = Join-Path $projectRoot "dist/Sarcophagus.love"
}
if ([string]::IsNullOrWhiteSpace($LoveArchive)) {
    $LoveArchive = Join-Path $projectRoot ".tools/love-$loveVersion/love-$loveVersion-win64.zip"
}
if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $OutputDirectory = Join-Path $projectRoot "dist"
}

$LoveFile = [IO.Path]::GetFullPath($LoveFile)
$LoveArchive = [IO.Path]::GetFullPath($LoveArchive)
$OutputDirectory = [IO.Path]::GetFullPath($OutputDirectory)

if (-not (Test-Path -LiteralPath $LoveFile -PathType Leaf)) {
    throw "Release archive not found: $LoveFile`nBuild dist/Sarcophagus.love first with scripts/build-love.sh."
}
if (-not (Test-Path -LiteralPath $manifestSource -PathType Leaf)) {
    throw "Windows application manifest not found: $manifestSource"
}
if (-not (Test-Path -LiteralPath $iconSource -PathType Leaf)) {
    throw "Windows application icon not found: $iconSource`nRegenerate platform icons with scripts/generate-platform-icons.sh."
}

function Get-LowercaseSha256([string]$Path) {
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Get-WindowsVersion([string]$ProjectVersion) {
    $parts = @($ProjectVersion.Split("."))
    $invalidParts = @($parts | Where-Object { $_ -notmatch "^[0-9]+$" })
    if ($parts.Count -gt 4 -or $invalidParts.Count -ne 0) {
        throw "version.txt cannot be represented as a Windows assembly version: $ProjectVersion"
    }
    while ($parts.Count -lt 4) {
        $parts += "0"
    }
    return $parts -join "."
}

function Get-TailSha256([string]$Path, [long]$Offset) {
    $stream = [IO.File]::OpenRead($Path)
    $sha256 = [Security.Cryptography.SHA256]::Create()
    try {
        $stream.Position = $Offset
        $hash = $sha256.ComputeHash($stream)
        return ([BitConverter]::ToString($hash)).Replace("-", "").ToLowerInvariant()
    }
    finally {
        $sha256.Dispose()
        $stream.Dispose()
    }
}

function Join-BinaryFiles([string[]]$Sources, [string]$Destination) {
    $output = [IO.File]::Create($Destination)
    try {
        foreach ($source in $Sources) {
            $input = [IO.File]::OpenRead($source)
            try {
                $input.CopyTo($output)
            }
            finally {
                $input.Dispose()
            }
        }
    }
    finally {
        $output.Dispose()
    }
}

$nativeManifestSource = @'
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;

public static class NativeManifestResource
{
    private const int ResourceTypeIcon = 3;
    private const int ResourceTypeGroupIcon = 14;
    private const int ResourceTypeManifest = 24;
    private const int ApplicationIconId = 1;
    private const int ApplicationManifestId = 1;
    private const uint LoadLibraryAsDataFile = 0x00000002;
    private const uint LoadLibraryAsImageResource = 0x00000020;

    [UnmanagedFunctionPointer(CallingConvention.Winapi)]
    private delegate bool EnumResourceLanguageCallback(
        IntPtr module,
        IntPtr type,
        IntPtr name,
        ushort language,
        IntPtr parameter);

    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern IntPtr LoadLibraryEx(
        string fileName,
        IntPtr file,
        uint flags);

    [DllImport("kernel32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool FreeLibrary(IntPtr module);

    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool EnumResourceLanguages(
        IntPtr module,
        IntPtr type,
        IntPtr name,
        EnumResourceLanguageCallback callback,
        IntPtr parameter);

    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern IntPtr FindResource(
        IntPtr module,
        IntPtr name,
        IntPtr type);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern IntPtr LoadResource(IntPtr module, IntPtr resource);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern IntPtr LockResource(IntPtr resourceData);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern uint SizeofResource(IntPtr module, IntPtr resource);

    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern IntPtr BeginUpdateResource(
        string fileName,
        [MarshalAs(UnmanagedType.Bool)] bool deleteExistingResources);

    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool UpdateResource(
        IntPtr update,
        IntPtr type,
        IntPtr name,
        ushort language,
        IntPtr data,
        uint dataSize);

    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool EndUpdateResource(
        IntPtr update,
        [MarshalAs(UnmanagedType.Bool)] bool discard);

    private static IntPtr IntegerResource(int value)
    {
        return new IntPtr(value);
    }

    private static Win32Exception LastError(string operation)
    {
        return new Win32Exception(Marshal.GetLastWin32Error(), operation);
    }

    private sealed class IconImage
    {
        public byte Width;
        public byte Height;
        public byte ColorCount;
        public byte Reserved;
        public ushort Planes;
        public ushort BitCount;
        public byte[] Data;
    }

    private static List<ushort> GetResourceLanguages(
        string path,
        int resourceType,
        int resourceId)
    {
        IntPtr module = LoadLibraryEx(
            path,
            IntPtr.Zero,
            LoadLibraryAsDataFile | LoadLibraryAsImageResource);
        if (module == IntPtr.Zero)
            throw LastError("LoadLibraryEx failed");

        var languages = new List<ushort>();
        EnumResourceLanguageCallback callback = delegate(
            IntPtr ignoredModule,
            IntPtr ignoredType,
            IntPtr ignoredName,
            ushort language,
            IntPtr ignoredParameter)
        {
            languages.Add(language);
            return true;
        };

        try
        {
            IntPtr manifest = FindResource(
                module,
                IntegerResource(resourceId),
                IntegerResource(resourceType));
            if (manifest == IntPtr.Zero)
                return languages;

            bool found = EnumResourceLanguages(
                module,
                IntegerResource(resourceType),
                IntegerResource(resourceId),
                callback,
                IntPtr.Zero);
            if (!found)
                throw LastError("EnumResourceLanguages failed");
        }
        finally
        {
            FreeLibrary(module);
        }

        return languages;
    }

    private static List<IconImage> ReadIconImages(string iconPath)
    {
        byte[] icon = File.ReadAllBytes(iconPath);
        var images = new List<IconImage>();
        using (var stream = new MemoryStream(icon, false))
        using (var reader = new BinaryReader(stream))
        {
            if (stream.Length < 6 || reader.ReadUInt16() != 0 || reader.ReadUInt16() != 1)
                throw new InvalidDataException("Invalid ICO header: " + iconPath);

            ushort count = reader.ReadUInt16();
            if (count == 0 || stream.Length < 6 + count * 16)
                throw new InvalidDataException("Invalid ICO directory: " + iconPath);

            for (int index = 0; index < count; index++)
            {
                var image = new IconImage();
                image.Width = reader.ReadByte();
                image.Height = reader.ReadByte();
                image.ColorCount = reader.ReadByte();
                image.Reserved = reader.ReadByte();
                image.Planes = reader.ReadUInt16();
                image.BitCount = reader.ReadUInt16();
                uint dataSize = reader.ReadUInt32();
                uint dataOffset = reader.ReadUInt32();

                if (dataSize == 0 || dataSize > Int32.MaxValue ||
                    dataOffset > Int32.MaxValue ||
                    (ulong)dataOffset + dataSize > (ulong)icon.LongLength)
                {
                    throw new InvalidDataException("Invalid ICO image range: " + iconPath);
                }

                image.Data = new byte[(int)dataSize];
                Buffer.BlockCopy(icon, (int)dataOffset, image.Data, 0, image.Data.Length);
                images.Add(image);
            }
        }
        return images;
    }

    private static byte[] BuildGroupIcon(List<IconImage> images)
    {
        using (var stream = new MemoryStream())
        using (var writer = new BinaryWriter(stream))
        {
            writer.Write((ushort)0);
            writer.Write((ushort)1);
            writer.Write((ushort)images.Count);
            for (int index = 0; index < images.Count; index++)
            {
                IconImage image = images[index];
                writer.Write(image.Width);
                writer.Write(image.Height);
                writer.Write(image.ColorCount);
                writer.Write(image.Reserved);
                writer.Write(image.Planes);
                writer.Write(image.BitCount);
                writer.Write((uint)image.Data.Length);
                writer.Write((ushort)(index + 1));
            }
            return stream.ToArray();
        }
    }

    private static void UpdateResourceBytes(
        IntPtr update,
        int resourceType,
        int resourceId,
        byte[] bytes,
        string operation)
    {
        GCHandle pinnedBytes = GCHandle.Alloc(bytes, GCHandleType.Pinned);
        try
        {
            if (!UpdateResource(
                update,
                IntegerResource(resourceType),
                IntegerResource(resourceId),
                0,
                pinnedBytes.AddrOfPinnedObject(),
                (uint)bytes.Length))
            {
                throw LastError(operation);
            }
        }
        finally
        {
            pinnedBytes.Free();
        }
    }

    private static byte[] ReadResourceBytes(
        IntPtr module,
        int resourceType,
        int resourceId)
    {
        IntPtr resource = FindResource(
            module,
            IntegerResource(resourceId),
            IntegerResource(resourceType));
        if (resource == IntPtr.Zero)
            throw LastError("FindResource failed");

        uint size = SizeofResource(module, resource);
        IntPtr loaded = LoadResource(module, resource);
        IntPtr data = LockResource(loaded);
        if (loaded == IntPtr.Zero || data == IntPtr.Zero || size == 0)
            throw LastError("Loading the resource failed");

        byte[] bytes = new byte[size];
        Marshal.Copy(data, bytes, 0, bytes.Length);
        return bytes;
    }

    private static bool BytesEqual(byte[] left, byte[] right)
    {
        if (left.Length != right.Length)
            return false;
        for (int index = 0; index < left.Length; index++)
        {
            if (left[index] != right[index])
                return false;
        }
        return true;
    }

    public static void ReplaceIcon(string executablePath, string iconPath)
    {
        string executable = Path.GetFullPath(executablePath);
        List<IconImage> images = ReadIconImages(iconPath);
        var iconLanguages = new List<List<ushort>>();
        for (int index = 0; index < images.Count; index++)
        {
            iconLanguages.Add(GetResourceLanguages(
                executable,
                ResourceTypeIcon,
                index + 1));
        }
        List<ushort> groupLanguages = GetResourceLanguages(
            executable,
            ResourceTypeGroupIcon,
            ApplicationIconId);

        IntPtr update = BeginUpdateResource(executable, false);
        if (update == IntPtr.Zero)
            throw LastError("BeginUpdateResource failed");

        bool completed = false;
        try
        {
            for (int index = 0; index < iconLanguages.Count; index++)
            {
                foreach (ushort language in iconLanguages[index])
                {
                    if (!UpdateResource(
                        update,
                        IntegerResource(ResourceTypeIcon),
                        IntegerResource(index + 1),
                        language,
                        IntPtr.Zero,
                        0))
                    {
                        throw LastError("Deleting an old icon image failed");
                    }
                }
            }
            foreach (ushort language in groupLanguages)
            {
                if (!UpdateResource(
                    update,
                    IntegerResource(ResourceTypeGroupIcon),
                    IntegerResource(ApplicationIconId),
                    language,
                    IntPtr.Zero,
                    0))
                {
                    throw LastError("Deleting the old icon group failed");
                }
            }

            for (int index = 0; index < images.Count; index++)
            {
                UpdateResourceBytes(
                    update,
                    ResourceTypeIcon,
                    index + 1,
                    images[index].Data,
                    "Embedding an icon image failed");
            }
            UpdateResourceBytes(
                update,
                ResourceTypeGroupIcon,
                ApplicationIconId,
                BuildGroupIcon(images),
                "Embedding the icon group failed");

            bool saved = EndUpdateResource(update, false);
            update = IntPtr.Zero;
            if (!saved)
                throw LastError("EndUpdateResource failed");
            completed = true;
        }
        finally
        {
            if (!completed && update != IntPtr.Zero)
                EndUpdateResource(update, true);
        }
    }

    public static bool IconMatches(string executablePath, string iconPath)
    {
        List<IconImage> expectedImages = ReadIconImages(iconPath);
        IntPtr module = LoadLibraryEx(
            Path.GetFullPath(executablePath),
            IntPtr.Zero,
            LoadLibraryAsDataFile | LoadLibraryAsImageResource);
        if (module == IntPtr.Zero)
            throw LastError("LoadLibraryEx failed");

        try
        {
            byte[] group = ReadResourceBytes(
                module,
                ResourceTypeGroupIcon,
                ApplicationIconId);
            using (var stream = new MemoryStream(group, false))
            using (var reader = new BinaryReader(stream))
            {
                if (stream.Length < 6 || reader.ReadUInt16() != 0 || reader.ReadUInt16() != 1)
                    return false;
                ushort count = reader.ReadUInt16();
                if (count != expectedImages.Count || stream.Length != 6 + count * 14)
                    return false;

                for (int index = 0; index < count; index++)
                {
                    IconImage expected = expectedImages[index];
                    if (reader.ReadByte() != expected.Width ||
                        reader.ReadByte() != expected.Height ||
                        reader.ReadByte() != expected.ColorCount ||
                        reader.ReadByte() != expected.Reserved ||
                        reader.ReadUInt16() != expected.Planes ||
                        reader.ReadUInt16() != expected.BitCount ||
                        reader.ReadUInt32() != expected.Data.Length)
                    {
                        return false;
                    }
                    ushort resourceId = reader.ReadUInt16();
                    if (resourceId != index + 1 ||
                        !BytesEqual(
                            ReadResourceBytes(module, ResourceTypeIcon, resourceId),
                            expected.Data))
                    {
                        return false;
                    }
                }
            }
            return true;
        }
        finally
        {
            FreeLibrary(module);
        }
    }

    public static void Replace(string executablePath, string manifestPath)
    {
        string executable = Path.GetFullPath(executablePath);
        byte[] manifest = File.ReadAllBytes(manifestPath);
        List<ushort> languages = GetResourceLanguages(
            executable,
            ResourceTypeManifest,
            ApplicationManifestId);
        IntPtr update = BeginUpdateResource(executable, false);
        if (update == IntPtr.Zero)
            throw LastError("BeginUpdateResource failed");

        bool completed = false;
        GCHandle pinnedManifest = default(GCHandle);
        try
        {
            foreach (ushort language in languages)
            {
                if (!UpdateResource(
                    update,
                    IntegerResource(ResourceTypeManifest),
                    IntegerResource(ApplicationManifestId),
                    language,
                    IntPtr.Zero,
                    0))
                {
                    throw LastError("Deleting the old manifest failed");
                }
            }

            pinnedManifest = GCHandle.Alloc(manifest, GCHandleType.Pinned);
            if (!UpdateResource(
                update,
                IntegerResource(ResourceTypeManifest),
                IntegerResource(ApplicationManifestId),
                0,
                pinnedManifest.AddrOfPinnedObject(),
                (uint)manifest.Length))
            {
                throw LastError("Embedding the new manifest failed");
            }

            bool saved = EndUpdateResource(update, false);
            update = IntPtr.Zero;
            if (!saved)
                throw LastError("EndUpdateResource failed");
            completed = true;
        }
        finally
        {
            if (pinnedManifest.IsAllocated)
                pinnedManifest.Free();
            if (!completed && update != IntPtr.Zero)
                EndUpdateResource(update, true);
        }
    }

    public static string Read(string executablePath)
    {
        IntPtr module = LoadLibraryEx(
            Path.GetFullPath(executablePath),
            IntPtr.Zero,
            LoadLibraryAsDataFile | LoadLibraryAsImageResource);
        if (module == IntPtr.Zero)
            throw LastError("LoadLibraryEx failed");

        try
        {
            IntPtr resource = FindResource(
                module,
                IntegerResource(ApplicationManifestId),
                IntegerResource(ResourceTypeManifest));
            if (resource == IntPtr.Zero)
                throw LastError("FindResource failed");

            uint size = SizeofResource(module, resource);
            IntPtr loaded = LoadResource(module, resource);
            IntPtr data = LockResource(loaded);
            if (loaded == IntPtr.Zero || data == IntPtr.Zero || size == 0)
                throw LastError("Loading the manifest resource failed");

            byte[] bytes = new byte[size];
            Marshal.Copy(data, bytes, 0, bytes.Length);
            return Encoding.UTF8.GetString(bytes).TrimStart('\uFEFF');
        }
        finally
        {
            FreeLibrary(module);
        }
    }
}
'@

if (-not ("NativeManifestResource" -as [type])) {
    Add-Type -TypeDefinition $nativeManifestSource -Language CSharp
}

$archiveParent = Split-Path -Parent $LoveArchive
New-Item -ItemType Directory -Force -Path $archiveParent | Out-Null
if (-not (Test-Path -LiteralPath $LoveArchive -PathType Leaf)) {
    Write-Host "Downloading the official LÖVE $loveVersion Windows x64 runtime..."
    Invoke-WebRequest -UseBasicParsing -Uri $loveRuntimeUrl -OutFile $LoveArchive
}

$runtimeHash = Get-LowercaseSha256 $LoveArchive
if ($runtimeHash -ne $loveRuntimeSha256) {
    throw "Unexpected LÖVE runtime checksum: $runtimeHash (expected $loveRuntimeSha256)"
}

$temporaryRoot = Join-Path $projectRoot "build/native/windows"
$runtimeRoot = Join-Path $temporaryRoot "runtime"
$runner = Join-Path $temporaryRoot "Sarcophagus-runner.exe"
$generatedManifest = Join-Path $temporaryRoot "Sarcophagus.exe.manifest"
$packageName = "Sarcophagus-windows-x64-$version"
$packageDirectory = Join-Path $OutputDirectory $packageName
$packageArchive = Join-Path $OutputDirectory "$packageName.zip"

if (Test-Path -LiteralPath $temporaryRoot) {
    Remove-Item -LiteralPath $temporaryRoot -Recurse -Force
}
if (Test-Path -LiteralPath $packageDirectory) {
    Remove-Item -LiteralPath $packageDirectory -Recurse -Force
}
if (Test-Path -LiteralPath $packageArchive) {
    Remove-Item -LiteralPath $packageArchive -Force
}
New-Item -ItemType Directory -Force -Path $runtimeRoot, $packageDirectory | Out-Null

Expand-Archive -LiteralPath $LoveArchive -DestinationPath $runtimeRoot
$runtimeExecutable = Get-ChildItem -LiteralPath $runtimeRoot -Recurse -Filter "love.exe" -File |
    Select-Object -First 1
if ($null -eq $runtimeExecutable) {
    throw "love.exe was not found in $LoveArchive"
}
$runtimeDirectory = $runtimeExecutable.Directory.FullName

Copy-Item -LiteralPath $runtimeExecutable.FullName -Destination $runner
$windowsVersion = Get-WindowsVersion $version
$manifestText = (Get-Content -LiteralPath $manifestSource -Raw).Replace(
    'version="0.0.0.0"',
    "version=`"$windowsVersion`"")
[IO.File]::WriteAllText(
    $generatedManifest,
    $manifestText,
    [Text.UTF8Encoding]::new($false))

[NativeManifestResource]::Replace($runner, $generatedManifest)
[NativeManifestResource]::ReplaceIcon($runner, $iconSource)
$embeddedManifest = [NativeManifestResource]::Read($runner)
if ($embeddedManifest -notmatch '<dpiAware[^>]*>true</dpiAware>' -or
    $embeddedManifest -notmatch '<dpiAwareness[^>]*>system</dpiAwareness>') {
    throw "The DPI-aware application manifest was not embedded correctly."
}
if (-not [NativeManifestResource]::IconMatches($runner, $iconSource)) {
    throw "The Windows application icon was not embedded correctly."
}

$outputExecutable = Join-Path $packageDirectory "Sarcophagus.exe"
$runnerLength = (Get-Item -LiteralPath $runner).Length
Join-BinaryFiles @($runner, $LoveFile) $outputExecutable

if ([NativeManifestResource]::Read($outputExecutable) -ne $embeddedManifest) {
    throw "The embedded manifest changed while fusing the game."
}
if (-not [NativeManifestResource]::IconMatches($outputExecutable, $iconSource)) {
    throw "The embedded icon changed while fusing the game."
}
if ((Get-TailSha256 $outputExecutable $runnerLength) -ne (Get-LowercaseSha256 $LoveFile)) {
    throw "The embedded .love archive failed its checksum verification."
}

Get-ChildItem -LiteralPath $runtimeDirectory -Filter "*.dll" -File | ForEach-Object {
    Copy-Item -LiteralPath $_.FullName -Destination $packageDirectory
}
Copy-Item -LiteralPath (Join-Path $runtimeDirectory "license.txt") -Destination $packageDirectory

Compress-Archive -Path (Join-Path $packageDirectory "*") -DestinationPath $packageArchive -CompressionLevel Optimal
$packageHash = Get-LowercaseSha256 $packageArchive

Write-Host "Built $packageDirectory"
Write-Host "Built $packageArchive"
Write-Host "SHA-256 $packageHash"
