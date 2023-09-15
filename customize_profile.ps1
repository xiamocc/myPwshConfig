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