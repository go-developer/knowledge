---
title: charles(抓包软件)安装及使用
categories:
  - tool
abbrlink: 36babffb
date: 2021-03-03 20:40:17
tags:
  - charles
  - 代理
  - 抓包
  - HTTPS
description: 抓包工具charles的安装与使用
cover: /img/tool/charles.png
---

## 前言

本文内容及相关操作基于  **`MacOS`**

## 抓包软件

 **`CharlesV4.6.1`**

## 证书安装

### 电脑安装证书

**`Help`** >  **`SSL Proxying`** >  **`Install Charles Root Certificate`**

### 手机安装证书

**`Help`** >  **`SSL Proxying`** >  **`Install Charles Root Certificate On a Mobile Device or Remote Browser`**

点击后会有如下提示 :

- 当前配置代理的电脑的 **`IP:PORT`**
- 使用手机浏览器访问  **`chls.pro/ssl`** 在手机上下载证书并安装
- IOS系统如果系统版本高于10, 需要在  **`Settings`** >  **`Generate`** >  **`About`** >  **`Certificate`**  对用户自行安装的证书进行授信,默认是不信任用户自行安装的证书的.

![电脑端提示如何在手机上安装证书](/img/tool/charles-install-certificate-on-mobile.png)

## 手机端代理的配置

以  **`荣耀V20`** 为例 :

 **`设置`** >  **`WLAN`** >  **`和电脑连接到同一个WIFI`** >  **`显示高级选线`** >  **`代理`** >  **`手动`** >  **`服务器主机即为你电脑的IP,服务器端口配置成你设置的端口即可(参照手机安装证书时的提示)`**

这个时候如果一切顺利, 访问一下百度,在charles终究可以看到相关请求了

![手机端WIFI配置](/img/tool/charles-mobil-wlan-config.jpeg)

### 注意事项

首次连接电脑代理时,电脑端会有一个授权弹窗,请选择  **`Allow(允许)`** , 不要选择  **`Deny(禁止)`** , 如果误选了，可以在  **`Proxy`** >  **`Access Control Settings...`** 将手机的IP手动加入授权列表. 如果新设备联入,不希望弹出授权弹窗, 可以去掉  **`Prompt to allow unauthorized connections`** 此选项默认是勾选的.

## HTTPS流量代理

经过上面一系列配置,HTTP流量抓包已经没问题,但是app抓包时,  **`Android`** 由于自身机制, HTTPS 流量无法抓取,显示  **`UNKNOWN`**, IOS 不存在此问题,此时需要如下方案解决

### 工具软件

- 下载并安装 [VirtualXposed](https://github.com/android-hacker/VirtualXposed/releases) , 最新版本不支持32位应用,需要支持32位应用可以降低下载的版本, 验证  **`Android 10 support`** 版本可以使用
- 下载并安装 [rustMeAlready](https://github.com/ViRb3/TrustMeAlready/releases)

### 软件安装

按照上面的连接下载安装即可, 打开  **`VirtualXposed`**, 点击底部的  **`带六个点点的圆圈`** , 第一次打开, 点击右下角的  **`+`** , 添加下载的  **`rustMeAlready`** , 添加成功后, 选择你要安装的APP, 选择好之后,点击 **`安装`** ,安装成功之后,  **`重启VirtualXposed`** ， 首页位置上滑, 可在列表中打开你已安装的应用

### 配置SSL

软件安装成功之后,抓包会发现流量依旧是加密的,因为还需要配置电脑的  **`charles`** :

 **`Proxy`** >  **`SSL Proxy Setting`** >  **`勾选Enable SSL Proxying`**

 点击  左侧 **`Include`** 下方的  **`Add`** , 添加你想转包的域名即可, 支持  **`*通配符`**, 只配置一个  **`*`**, 所有 HTTPS 流量都会解析. 特定域名 HTTPS 流量不想处理,可以添加到 **`Exclude`** 中.

## 常用配置

### 代理端口的配置

charles默认的代理端口为  **`8888`** , 此端口极容易被其他服务占用,通过如下路径配置:

 **`Proxy`** >  **`Proxy Setting`** >  **`Proxies`** , 修改  **`Http Proxy 下的 Port 即可`**

### 远端代理

 **`Tools`** >  **`Map Remote`** >  **`勾选 Enable Map Remote`** , 点击  **`Add`** , 按提示添加配置即可。 同时支持配置的 **`导入与导出`**

### 本地代理

**`Tools`** >  **`Map Remote`** >  **`勾选 Enable Map Remote`** , 点击  **`Add`** , 按提示添加配置即可。 同时支持配置的 **`导入与导出`**

注意: 此配置  **`Map From`** 配置规则与  **`远端代理`** 完全一致, 区别是  **`Map To`** 需要选择一个本地文件, 填入  **`文件全路径`**, 会用文件内容,最为请求的响应信息.
