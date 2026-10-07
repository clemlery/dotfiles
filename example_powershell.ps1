# Ouvre le fichier en lecture seule sous forme de flux binaire
$in = [System.IO.File]::OpenRead($path)
# Enveloppe le flux dans un décompresseur GZip (décompression à la volée)
$gz = New-Object System.IO.Compression.GZipStream($in, [System.IO.Compression.CompressionMode]::Decompress)
# Lit le flux décompressé comme du texte encodé en UTF-8
$rd = New-Object System.IO.StreamReader($gz, [System.Text.Encoding]::UTF8)
$buf = New-Object char[] 4000
# Lit au plus 4000 caractères et retourne le nombre réellement lus
$n = $rd.Read($buf, 0, 4000)
# Reconstruit la chaîne à partir des seuls caractères effectivement lus
-join $buf[0..($n - 1)]
$rd.Close()