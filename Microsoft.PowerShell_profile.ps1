using namespace System.Management.Automation
using namespace System.Management.Automation.Language

if ($host.Name -eq 'ConsoleHost')
{
    Import-Module PSReadLine
}

Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -EditMode Windows

# 設定按下 Ctrl+d 可以退出 PowerShell 執行環境
Set-PSReadlineKeyHandler -Chord ctrl+d -Function ViExit

# 設定按下 Ctrl+w 可以刪除一個單字
Set-PSReadlineKeyHandler -Chord ctrl+w -Function BackwardDeleteWord

# 設定按下 Ctrl+e 可以移動游標到最後面(End)
Set-PSReadlineKeyHandler -Chord ctrl+e -Function EndOfLine

# 設定按下 Ctrl+a 可以移動游標到最前面(Begin)
Set-PSReadlineKeyHandler -Chord ctrl+a -Function BeginningOfLine

#Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
#Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

# This key handler shows the entire or filtered history using Out-GridView. The
# typed text is used as the substring pattern for filtering. A selected command
# is inserted to the command line without invoking. Multiple command selection
# is supported, e.g. selected by Ctrl + Click.
Set-PSReadLineKeyHandler -Key F7 `
                         -BriefDescription History `
                         -LongDescription 'Show command history' `
                         -ScriptBlock {
    $pattern = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$pattern, [ref]$null)
    if ($pattern)
    {
        $pattern = [regex]::Escape($pattern)
    }

    $history = [System.Collections.ArrayList]@(
        $last = ''
        $lines = ''
        foreach ($line in [System.IO.File]::ReadLines((Get-PSReadLineOption).HistorySavePath))
        {
            if ($line.EndsWith('`'))
            {
                $line = $line.Substring(0, $line.Length - 1)
                $lines = if ($lines)
                {
                    "$lines`n$line"
                }
                else
                {
                    $line
                }
                continue
            }

            if ($lines)
            {
                $line = "$lines`n$line"
                $lines = ''
            }

            if (($line -cne $last) -and (!$pattern -or ($line -match $pattern)))
            {
                $last = $line
                $line
            }
        }
    )
    $history.Reverse()

    $command = $history | Out-GridView -Title History -PassThru
    if ($command)
    {
        [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert(($command -join "`n"))
    }
}


# F1 for help on the command line - naturally
# Set-PSReadLineKeyHandler -Key F1 `
#                          -BriefDescription CommandHelp `
#                          -LongDescription "Open the help window for the current command" `
#                          -ScriptBlock {
#     param($key, $arg)

#     $ast = $null
#     $tokens = $null
#     $errors = $null
#     $cursor = $null
#     [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$ast, [ref]$tokens, [ref]$errors, [ref]$cursor)

#     $commandAst = $ast.FindAll( {
#         $node = $args[0]
#         $node -is [CommandAst] -and
#             $node.Extent.StartOffset -le $cursor -and
#             $node.Extent.EndOffset -ge $cursor
#         }, $true) | Select-Object -Last 1

#     if ($commandAst -ne $null)
#     {
#         $commandName = $commandAst.GetCommandName()
#         if ($commandName -ne $null)
#         {
#             $command = $ExecutionContext.InvokeCommand.GetCommand($commandName, 'All')
#             if ($command -is [AliasInfo])
#             {
#                 $commandName = $command.ResolvedCommandName
#             }

#             if ($commandName -ne $null)
#             {
#                 Get-Help $commandName -ShowWindow
#             }
#         }
#     }
# }

Set-PSReadLineKeyHandler -Key '"',"'" `
                         -BriefDescription SmartInsertQuote `
                         -LongDescription "Insert paired quotes if not already on a quote" `
                         -ScriptBlock {
    param($key, $arg)

    $quote = $key.KeyChar

    $selectionStart = $null
    $selectionLength = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetSelectionState([ref]$selectionStart, [ref]$selectionLength)

    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

    # If text is selected, just quote it without any smarts
    if ($selectionStart -ne -1)
    {
        [Microsoft.PowerShell.PSConsoleReadLine]::Replace($selectionStart, $selectionLength, $quote + $line.SubString($selectionStart, $selectionLength) + $quote)
        [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($selectionStart + $selectionLength + 2)
        return
    }

    $ast = $null
    $tokens = $null
    $parseErrors = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$ast, [ref]$tokens, [ref]$parseErrors, [ref]$null)

    function FindToken
    {
        param($tokens, $cursor)

        foreach ($token in $tokens)
        {
            if ($cursor -lt $token.Extent.StartOffset) { continue }
            if ($cursor -lt $token.Extent.EndOffset) {
                $result = $token
                $token = $token -as [StringExpandableToken]
                if ($token) {
                    $nested = FindToken $token.NestedTokens $cursor
                    if ($nested) { $result = $nested }
                }

                return $result
            }
        }
        return $null
    }

    $token = FindToken $tokens $cursor

    # If we're on or inside a **quoted** string token (so not generic), we need to be smarter
    if ($token -is [StringToken] -and $token.Kind -ne [TokenKind]::Generic) {
        # If we're at the start of the string, assume we're inserting a new string
        if ($token.Extent.StartOffset -eq $cursor) {
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert("$quote$quote ")
            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
            return
        }

        # If we're at the end of the string, move over the closing quote if present.
        if ($token.Extent.EndOffset -eq ($cursor + 1) -and $line[$cursor] -eq $quote) {
            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
            return
        }
    }

    if ($null -eq $token -or
        $token.Kind -eq [TokenKind]::RParen -or $token.Kind -eq [TokenKind]::RCurly -or $token.Kind -eq [TokenKind]::RBracket) {
        if ($line[0..$cursor].Where{$_ -eq $quote}.Count % 2 -eq 1) {
            # Odd number of quotes before the cursor, insert a single quote
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert($quote)
        }
        else {
            # Insert matching quotes, move cursor to be in between the quotes
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert("$quote$quote")
            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
        }
        return
    }

    # If cursor is at the start of a token, enclose it in quotes.
    if ($token.Extent.StartOffset -eq $cursor) {
        if ($token.Kind -eq [TokenKind]::Generic -or $token.Kind -eq [TokenKind]::Identifier -or 
            $token.Kind -eq [TokenKind]::Variable -or $token.TokenFlags.hasFlag([TokenFlags]::Keyword)) {
            $end = $token.Extent.EndOffset
            $len = $end - $cursor
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace($cursor, $len, $quote + $line.SubString($cursor, $len) + $quote)
            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($end + 2)
            return
        }
    }

    # We failed to be smart, so just insert a single quote
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert($quote)
}

Set-PSReadLineKeyHandler -Key '(','{','[' `
                         -BriefDescription InsertPairedBraces `
                         -LongDescription "Insert matching braces" `
                         -ScriptBlock {
    param($key, $arg)

    $closeChar = switch ($key.KeyChar)
    {
        <#case#> '(' { [char]')'; break }
        <#case#> '{' { [char]'}'; break }
        <#case#> '[' { [char]']'; break }
    }

    $selectionStart = $null
    $selectionLength = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetSelectionState([ref]$selectionStart, [ref]$selectionLength)

    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
    
    if ($selectionStart -ne -1)
    {
      # Text is selected, wrap it in brackets
      [Microsoft.PowerShell.PSConsoleReadLine]::Replace($selectionStart, $selectionLength, $key.KeyChar + $line.SubString($selectionStart, $selectionLength) + $closeChar)
      [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($selectionStart + $selectionLength + 2)
    } else {
      # No text is selected, insert a pair
      [Microsoft.PowerShell.PSConsoleReadLine]::Insert("$($key.KeyChar)$closeChar")
      [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
    }
}

Set-PSReadLineKeyHandler -Key ')',']','}' `
                         -BriefDescription SmartCloseBraces `
                         -LongDescription "Insert closing brace or skip" `
                         -ScriptBlock {
    param($key, $arg)

    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

    if ($line[$cursor] -eq $key.KeyChar)
    {
        [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
    }
    else
    {
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert("$($key.KeyChar)")
    }
}

Set-PSReadLineKeyHandler -Key Backspace `
                         -BriefDescription SmartBackspace `
                         -LongDescription "Delete previous character or matching quotes/parens/braces" `
                         -ScriptBlock {
    param($key, $arg)

    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

    if ($cursor -gt 0)
    {
        $toMatch = $null
        if ($cursor -lt $line.Length)
        {
            switch ($line[$cursor])
            {
                <#case#> '"' { $toMatch = '"'; break }
                <#case#> "'" { $toMatch = "'"; break }
                <#case#> ')' { $toMatch = '('; break }
                <#case#> ']' { $toMatch = '['; break }
                <#case#> '}' { $toMatch = '{'; break }
            }
        }

        if ($toMatch -ne $null -and $line[$cursor-1] -eq $toMatch)
        {
            [Microsoft.PowerShell.PSConsoleReadLine]::Delete($cursor - 1, 2)
        }
        else
        {
            [Microsoft.PowerShell.PSConsoleReadLine]::BackwardDeleteChar($key, $arg)
        }
    }
}

######################################################################################################################

# winget parameter completion
Register-ArgumentCompleter -Native -CommandName winget -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
        [Console]::InputEncoding = [Console]::OutputEncoding = $OutputEncoding = [System.Text.Utf8Encoding]::new()
        $Local:word = $wordToComplete.Replace('"', '""')
        $Local:ast = $commandAst.ToString().Replace('"', '""')
        winget complete --word="$Local:word" --commandline "$Local:ast" --position $cursorPosition | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
}

# PowerShell parameter completion shim for the dotnet CLI
Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock {
     param($commandName, $wordToComplete, $cursorPosition)
         dotnet complete --position $cursorPosition "$wordToComplete" | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
     }
}

######################################################################################################################

# 快速開啟 c:\windows\system32\drivers\etc\hosts 檔案
function hosts { notepad c:\windows\system32\drivers\etc\hosts }

If (Test-Path Alias:curl) {Remove-Item Alias:curl}
If (Test-Path Alias:wget) {Remove-Item Alias:wget}

######################################################################################################################

Clear-Host

######################################################################################################################


# oh-my-posh init pwsh --config ~/.ohmyposhv3-will.omp.json | Invoke-Expression
oh-my-posh init pwsh --config C:\Users\Helix\AppData\Local\Programs\oh-my-posh\themes\mojada.omp.json | Invoke-Expression

Import-Module -Name Terminal-Icons

######################################################################################################################

# git
function status { git status }

function clone { Param($0) git clone $0 }

function commit { Param($0) git commit -m "$0" }

function pull { git pull }

function push { git push }

$PROPATH = "E:\Users\Helix\Documents\PowerShell"
function gld {
  zx --experimental $PROPATH\ctlscript.mjs -f gitlog -m day
}

function glt {
  zx --experimental $PROPATH\ctlscript.mjs -f gitlog -m type
}

# npm

function nit { npm init }

function nps { npm start }

function npr { npm run $1 }

function ns { npm run serve }

function nb { npm run build }

# yarn

function ysl { yarn run serve:local }

function ys {
    Param($0)
    $mode = "serve"
    if ([System.IO.File]::Exists("./vite.config.js")) { $mode = "dev" }
    if ($0) { yarn ${mode}:$0} else { yarn $mode}
}

# function ys { yarn dev }

function yb {
    Param($0)
    if ($0) {
        yarn build:$0
    } else {
        yarn build
    }
}   

function ybi { yarn build:inside }

function yi { yarn install }

function yp { yarn publish }

function yd { Param($0) yarn add $0 }

function ydd { Param($0) yarn add -D $0 }

function yu { yarn upgrade }

function bz {
    yb && ybi
    rz
}

function rz {
    rez
    if (Test-Path -Path ./dist) { zip -r dist.zip dist }
    if (Test-Path -Path ./inside) { zip -r inside.zip inside }
}

function rez {
    if ([System.IO.File]::Exists("./dist.zip")) { rimraf dist.zip }
    if ([System.IO.File]::Exists("./inside.zip")) { rimraf inside.zip }
}

# workspace

function wk { cd D:\Work }

function cl { clear }

function cpw {
    $propath = Split-Path -Path $profile
    code $propath
} 
function pw {
    $propath = Split-Path -Path $profile
    cd $propath
} 
function pf { code $PROFILE}

function cc { code . }

function co { Param($0) cd $0 ; cc }

function mk { Param($0) mkdir $0 ; cd $0 }

function pp { pwsh }
