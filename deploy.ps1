npm run build

if ($LASTEXITCODE -eq 0) {
    Set-Location .\dist
    
    git init
    git add -A
    git commit -m "deploy"
    git push -f https://github.com/lampepfl/lsp-viewer.git master:gh-pages

    Set-Location ..
}
