Add-Type -AssemblyName System.Drawing
$out = Join-Path $PSScriptRoot 'review'
New-Item -ItemType Directory -Force $out | Out-Null
foreach ($label in @('tiro_pet_puppy','tiro_pet')) {
  $dirs = @(Get-ChildItem "game/assets/sprites/characters/$label" -Directory | Where-Object { Test-Path (Join-Path $_.FullName 'frame_00.png') })
  for ($start=0; $start -lt $dirs.Count; $start+=6) {
    $group = @($dirs | Select-Object -Skip $start -First 6)
    $sheet = New-Object System.Drawing.Bitmap 1100,($group.Count*240)
    $g = [System.Drawing.Graphics]::FromImage($sheet)
    $g.Clear([System.Drawing.Color]::FromArgb(110,115,120))
    $g.InterpolationMode = 'NearestNeighbor'
    $font = New-Object System.Drawing.Font 'Arial',11
    for ($r=0; $r -lt $group.Count; $r++) {
      $files = @(Get-ChildItem $group[$r].FullName -Filter 'frame_*.png' | Sort-Object Name)
      $indices = @(0,[int][Math]::Floor($files.Count/4),[int][Math]::Floor($files.Count/2),[int][Math]::Floor(3*$files.Count/4),($files.Count-1) | Select-Object -Unique)
      for ($c=0; $c -lt $indices.Count; $c++) {
        $i=$indices[$c]; $im=[System.Drawing.Image]::FromFile($files[$i].FullName)
        $scale=[Math]::Min(210.0/$im.Width,210.0/$im.Height)
        $g.DrawImage($im,[System.Drawing.Rectangle]::new($c*220,$r*240+24,[int]($im.Width*$scale),[int]($im.Height*$scale)))
        $g.DrawString(($group[$r].Name+' '+$i),$font,[System.Drawing.Brushes]::White,$c*220,$r*240)
        $im.Dispose()
      }
    }
    $sheet.Save((Join-Path $out ($label+'_'+$start+'.png')))
    $g.Dispose();$sheet.Dispose();$font.Dispose()
  }
}
