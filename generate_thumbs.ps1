<#
  generate_thumbs.ps1 — Gerador de thumbnails e versoes "large" (Windows, sem dependencias).
  Usa System.Drawing (GDI+). Espelha assets\ em dois destinos, sempre .jpg:

    assets\thumbs\  -> grade        (max 900px,  JPEG q82)
    assets\large\   -> lightbox     (max 2560px, JPEG q88)  — evita baixar PNGs de 10-20 MB

  Achata sobre fundo branco (seguro para PNG com transparencia).
  Ignora thumbs\, large\, videos\ e PDFs. Mantem o mesmo caminho/case da origem.

  Uso:
    ./generate_thumbs.ps1          # gera apenas os que faltam / desatualizados
    ./generate_thumbs.ps1 -Force   # regenera todos
#>
param([switch]$Force)

Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

$assets = Join-Path $PSScriptRoot 'assets'
$targets = @(
  @{ Root = (Join-Path $assets 'thumbs'); Max = 900.0;  Q = 82 },
  @{ Root = (Join-Path $assets 'large');  Max = 2560.0; Q = 88 }
)

$jpgEnc = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }

$imgs = Get-ChildItem -LiteralPath $assets -Recurse -File |
        Where-Object { $_.Extension -match '(?i)\.(jpe?g|png)$' -and
                       $_.FullName -notmatch '[\\/](thumbs|large|videos|360|lib)[\\/]' -and
                       $_.Name -notmatch '^close-' }

$made = 0; $skip = 0
foreach ($f in $imgs) {
  $rel = $f.FullName.Substring($assets.Length).TrimStart('\')
  $relJpg = [System.IO.Path]::ChangeExtension($rel, '.jpg')
  foreach ($t in $targets) {
    $dest = Join-Path $t.Root $relJpg
    $destDir = Split-Path $dest -Parent
    if (-not (Test-Path -LiteralPath $destDir)) { New-Item -ItemType Directory -Force -Path $destDir | Out-Null }
    if (-not $Force -and (Test-Path -LiteralPath $dest) -and ((Get-Item -LiteralPath $dest).LastWriteTime -ge $f.LastWriteTime)) { $skip++; continue }
    try {
      $encParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
      $encParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [long]$t.Q)
      $img = [System.Drawing.Image]::FromFile($f.FullName)
      $scale = [Math]::Min($t.Max/$img.Width, $t.Max/$img.Height)
      if ($scale -gt 1) { $scale = 1 }
      $w = [int]($img.Width*$scale); $h = [int]($img.Height*$scale)
      $bmp = New-Object System.Drawing.Bitmap($w,$h)
      $g = [System.Drawing.Graphics]::FromImage($bmp)
      $g.Clear([System.Drawing.Color]::White)
      $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
      $g.PixelOffsetMode   = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
      $g.SmoothingMode     = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
      $g.DrawImage($img, 0, 0, $w, $h)
      $bmp.Save($dest, $jpgEnc, $encParams)
      $g.Dispose(); $bmp.Dispose(); $img.Dispose()
      $made++
      Write-Host ("  {0}\{1}  ->  {2} KB" -f (Split-Path $t.Root -Leaf), $relJpg, [Math]::Round((Get-Item -LiteralPath $dest).Length/1KB))
    } catch {
      Write-Host "ERRO em $rel : $($_.Exception.Message)" -ForegroundColor Red
    }
  }
}
Write-Host ("Gerados: {0} | Pulados: {1}" -f $made, $skip) -ForegroundColor Green
