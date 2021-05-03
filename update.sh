#!/bin/bash

shellDir="$(cd "$(dirname "$0")" && pwd)"

# 脚本和项目路径同级
cd $shellDir

logFile=/tmp/knowledge-publish.log

if [ ! -f "$logFile" ]; then
    touch "$logFile"
fi

# 拉取最新代码
git pull

# 读取上一次的版本号
lastCommitID=$(cat $logFile)

# 获取当前版本号
commitID=$(git rev-parse HEAD)

if [ "$lastCommitID" == "$commitID" ]; then
    exit 0
fi

# 生成静态文件
hexo generate

#  更新版本号
echo "$commitID" >$logFile
