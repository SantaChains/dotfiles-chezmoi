# 把选中文件以「文件对象」写入 Windows 剪贴板（可直接粘到资源管理器）。
# 由 keymap.toml 的 y y 调用，路径由 yazi 以双引号形式逐个传入。
$paths = $args
if (-not $paths -or $paths.Count -eq 0) { exit 1 }

$full = foreach ($p in $paths) {
    (Resolve-Path -LiteralPath $p).ProviderPath
}
Set-Clipboard -LiteralPath $full
