[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8

function Test-Ignore($dir) {
  $dirName = $dir.FullName.toString()
  if ($dirName -match ".*\.obsidian.*") {
    Write-Host "ignoring: ${dirName}"
    return $true
  }
  return $false
}

function New-Content($dir, $folderName, $baseFullPath, $targetFileName, $PREFIX) {
  # ファイル内容
  $content = ""
  $content +=
@'
|ファイル名|更新日時|Link|
|-----|-----|-----|

'@
  # ディレクトリにあるすべてのファイル情報を取得する
  $files = $dir.GetFiles()
  # ディレクトリにあるファイルの内容とリンクを書き込む
  ForEach ($file in $files) {
    # 以下の場合文字列は追記しない
    # .mdファイルで終わらない場合、ディレクトリの場合、作成対象のファイルの場合
    if (!$file.name.ToString().EndsWith(".md") -or $file -is [System.IO.DirectoryInfo] -or 
    $file.name.ToString() -eq "${targetFileName}") {
      continue
    }
    # row情報を追記する
    $content += "|" + ($file.Name -Replace "\.md", "")
    $content += "|" + $file.LastWriteTime.ToString("yyyy/MM/dd HH:mm:ss")
    $content += "|[[" + $file.Name + "]]|`n"
  }
  if ($dir -eq $baseFullPath) {
    return $content
  }
  # 探索中のディレクトリ内のディレクトリを検索
  $dirs = Get-ChildItem -Path $dir.FullName -Directory
  ForEach ($directory in $dirs) {
    $dirName = $PREFIX + '_' + $directory.Name
    $dirName = $dirName -Replace '\s+', '_'
    $content += "|" + ($directory.Name -Replace "\.md", '')
    $content += "|"
    $content += "|[[" + $dirName + "]]|`n"
  }
  return $content
}

function New-File($content, $tmpFileName, $targetFileName) {
  $content | Out-File -FilePath $tmpFileName -Encoding utf8
  Rename-Item -Path $tmpFileName -NewName $targetFileName
  Write-Host "made file: ${targetFileName}"
}

function Remove-ExistFile($file) {
  Remove-Item -Path $file
}

function Remove-BaseFile($file) {
  $firstLine = Get-Content -Path $file -TotalCount 1 -Encoding UTF8
  if (
    $firstLine.contains("|") -and 
  $firstLine.contains("ファイル名") -and 
  $firstLine.contains("更新日時") -and 
  $firstLine.Contains("Link")) {
    Remove-ExistFile($file)
  }
}

# 主処理
$path = Get-Location
$baseFullPath = $path.Path
[System.IO.DirectoryInfo[]] $dirs = Get-ChildItem $Path -Recurse -Directory

foreach ($dir in $dirs) {
  $dirName = $dir.FullName.toString()
  if (Test-Ignore $dir) {
      continue;
  }
  foreach ($file in $dir.GetFiles()) {
    Remove-BaseFile($file.FullName)
  }
  $PREFIX = ($dirName).Replace($baseFullPath, '') -Replace '\\', '_'
  $PREFIX = $PREFIX -Replace '\s+', '_'
  # Baseファイルの形式でマークダウンファイルを生成する
  # Baseファイルが存在しない場合ファイルを作成する
  # フォルダの名前のスペースをアンダーバーに変換したもの
  $folderName = (Split-Path $dirName -Leaf) -Replace '\s+', '_'
  # 作成対象のmdファイル名
  $targetFileName = "${dirName}\${PREFIX}.md"
  # 一時テキストファイル名
  $targetTmpFileName = "${dirName}\${folderName}.txt"

  #作成対象のファイルが存在する場合消去
  if (Test-Path $targetTmpFileName) {
    Remove-Item -Path $targetTmpFileName
  }
  if (Test-Path $targetFileName) {
    Remove-Item -Path $targetFileName
  }
  #作成対象のファイルのコンテンツ生成
  $content = New-Content $dir $folderName $baseFullPath $targetFileName $PREFIX

  # 作成対象ファイル判定
  $mdExist = Test-Path -Path $targetFileName
  $txtExist = Test-Path -Path targetTmpFileName
  # 新規作成
  if ((-not $mdExist) -and (-not $txtExist)) {
    New-File $content $targetTmpFileName $targetFileName
  } 
  # 編集
  else {
    if (Test-Path $targetTmpFileName) {
      Remove-Item -Path $targetTmpFileName
    }
    if (Test-Path $targetFileName) {
      Remove-Item -Path $targetFileName
    }
    New-File $content $targetTmpFileName $targetFileName
  }
}
