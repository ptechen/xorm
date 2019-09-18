#! /bin/bash
databaseName=demo
projectName=demo
$GOPATH/bin/xorm reverse \
  mysql taochen:123456@tcp\(127.0.01:3306\)/${databaseName}?charset=utf8mb4 \
  $GOPATH/pkg/mod/github.com/hsyan2008/hfw2@v0.0.0-20190718064101-4aa5d5ec02f3/xorm \
  $GOPATH/src/ifchange/${projectName}/models $1
#  $GOPATH/pkg/mod/gitlab.ifchange.com/bot/hfw@v1.0.1/xorm \
