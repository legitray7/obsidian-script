$path = Get-Location
$files = Get-ChildItem $path -File

if (-not (Test-Path -Path ($path.FullName + "Images") -PathType Container)) {
    New-Item -Path ($path.FullName + "Images") -ItemType Directory
}
$imgPrefix = @(".jpg", ".jpeg", ".png", ".gif", ".bmp", ".tif", "tiff", ".heic", ".avif")
foreach ($file in $files) {
    foreach ($prefix in $imgPrefix) {

        # 後方一致
        if ($file.Name -match (".*" + $prefix + "$")) {
            Move-Item -Path $file.FullName -Destination ($path.FullName + "Images")
        }
    }
}