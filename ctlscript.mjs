echo('=========================start===========================')
$.verbose = false
switch (argv.f) {
  case 'fix':
    autoFix(argv)
    break
  case 'gitlog':
    getGitLog(argv)
    break
}

async function autoFix(argv) {
  $.verbose = true
  if (argv.m === 'sass') {
    await $`cd ./node_modules/ && sass-migrator division **/*.scss`
    echo('执行完毕')
  } else {
    echo('请传入执行模式')
  }
  end()
  $.verbose = false
}

async function getGitLog() {
  var dayjs = require('dayjs')
  const types = require('./config/types.json')
  const localUser = await $`git config user.name`
  const username = Object.hasOwnProperty.call(argv, 'u') ? argv.u : localUser
  const totalNum = Object.hasOwnProperty.call(argv, 'd') ? Number(argv.d) : 5
  if (argv.m === 'day') {
    const dates = Array.from({ length: totalNum }, (v, k) => dayjs().subtract(k, 'days').format('YYYY.MM.DD')).reverse()
    for (let i = 0; i < dates.length; i++) {
      const date = dates[i]
      var logResource =
        await $`git log --author="${username}" --no-merges --pretty=format:"%s" --after="${date} 00:00" --before="${date} 24:00"`
      $.verbose = true
      echo(`\n${date}`)
      echo(logResource)
      $.verbose = false
    }
    end()
  } else {
    const logs = await $`git log --author="${username}" --no-merges --pretty=format:"%s" --after="${totalNum}.day"`
    const logsArr = logs.stdout.replace(/\n/g, '*/*/*').split('*/*/*')
    for (let i = 0; i < types.length; i++) {
      const ele = types[i]
      types[i]['list'] = []
      const temp = []
      for (let li = 0; li < logsArr.length; li++) {
        const le = logsArr[li]
        if (eval(`/${ele.name}/`).test(le) || eval(`/'${ele.name}'/`).test(le)) {
          temp.push(li)
          types[i]['list'].push(le)
        }
        if (ele.name === 'undefined' && le) {
          types[i]['list'].push(le)
        }
      }
      for (let ei = 0; ei < temp.length; ei++) {
        delete logsArr[temp[ei]]
      }
    }
    $.verbose = true
    for (const key in types) {
      const element = types[key]
      if (element.list.length > 0) {
        const consoleList = element.list.filter((test) => {
          return test !== undefined
        })
        if (consoleList.length > 0) {
          echo(`\n${element.label.trim()}`)
          echo(`${consoleList.join('\n').trim()}`)
        }
      }
    }
    end()
  }
}
function end() {
  echo('\n==========================end============================')
}
