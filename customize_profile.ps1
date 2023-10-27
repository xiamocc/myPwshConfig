function echoInfo {
    Param($0, $1)
    Write-Host "`e[$($0)m$1`e[0m"
}

# git
function status { git status }

function clone { Param($0) git clone $0 }

function commit { Param($0) git commit -m "$0" }

function pull { git pull }

function push { git push }

function gld {
  zx --experimental $PSScriptRoot\ctlscript.mjs -f gitlog -m day
}

function glt {
  zx --experimental $PSScriptRoot\ctlscript.mjs -f gitlog -m type
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

function ybd {
    $start1 = Get-Date
    yarn build:develop
    $end1 = Get-Date
    echoInfo 32 ('==========> Build Runtime: ' + ($end1 - $start1).TotalSeconds)
}

function ybp {
    $start2 = Get-Date
    yarn build:production
    $end2 = Get-Date
    echoInfo 32 ('==========> Build Runtime: ' + ($end2 - $start2).TotalSeconds)
}

function yi { yarn install }

function yp { yarn publish }

function yr { Param($0) yarn remove $0 }

function yd { Param($0) yarn add $0 }

function ydd { Param($0) yarn add -D $0 }

function yu { yarn upgrade }

function bz {
    Param($0)
    if(!$0) { $0 = 0 }
    $start = Get-Date
    echoInfo 32 ('==========> Now DateTime: ' + $start)
    $text = "==========> Start:build"
    echoInfo 32 $text
    if($0 -eq 0) {
        $text = "==========> Build:develop"
        echoInfo 32 $text
        $Null = ybd
    } else {
        $text = "==========> Build:production"
        echoInfo 32 $text
        $Null = ybp
    }
    zb
    $end = Get-Date
    echoInfo 91 ('==========> Total Runtime: ' + ($end - $start).TotalSeconds)
    echoInfo 32 ('==========> Now DateTime: ' + $end)
}

function zb {
    $text = "==========> Suppress:folder"
    echoInfo 32 $text
    rz
    if (Test-Path -Path ./dist) { $Null = zip -r dist.zip dist }
    if (Test-Path -Path ./inside) { $Null = zip -r inside.zip inside }
}

function rz {
    $text = "==========> Delete:oldzip"
    echoInfo 32 $text
    if ([System.IO.File]::Exists("./dist.zip")) { rimraf dist.zip }
    if ([System.IO.File]::Exists("./inside.zip")) { rimraf inside.zip }
}

# workspace

function wk { cd D:\Work }

function cl { clear }


# Profile配置相关

function pw {
    cd $PSScriptRoot
} 
function cpw {
    code $PSScriptRoot
} 
function cmp {
    echo $PSScriptRoot\customize_profile.ps1
} 
function pf { code $PROFILE}


# 快捷操作

function cc { code . }

function co { Param($0) cd $0 ; cc }

function mk { Param($0) mkdir $0 ; cd $0 }

function pp { pwsh }

# route 操作

function rl{ route print -4 }

function rdra { route delete 218.93.20.10 && route add 218.93.20.10 mask 255.255.255.255 192.168.31.1 }