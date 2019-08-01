# 国密

提供国密算法、国密VPN和国密浏览器技术支持、方案设计与实现。

## 国密算法

  - 软算法-`OpenSSL/BoringSSL`源码支持
  - 硬件支持-国密USB KEY（海泰方圆、飞天诚信、渔翁科技），使用`OpenSSL`的`engine`源码方式（包括Windows和Linux平台）


软算法:
  - 算法添加方式，从零添加完整的（`SM2/3/4`）算法实现
  - 源码测试`demo`
  - 文档说明，介绍接口使用方式和异常排查

国标`USB KEY`:
  - 使用 `OpenSSL` 提供的 `engine` 实现对国密 `USB KEY` 支持 
  - `engine` 便于添加和移除新硬件（测过海泰方圆、飞天诚信和渔翁科技的国密 `USB KEY`）
  - `BoringSSL` 的 `engine` 实现


## 国标VPN 

**《GM/T 0024-2014 SSL VPN技术规范》** 在`OpenSSL/BoringSSL` 的实现，实现的VPN能够与国家商用密码检测中心的测试机通信，并详细说明哪些部分与标准文档中有差异，便于了解实现流程。

基于OpenSSL开源的国密VPN工程有[GmSSL](https://github.com/guanzhi/GmSSL)和[TaSSL](https://github.com/jntass/TASSL) [TaSSL-1.1.1b](https://github.com/jntass/TASSL-1.1.1b)，有兴趣的可以参考其实现方式。最新的`OpenSSL-3.x.x`算法添加方式与以往的版本存在差异。

* 国密证书 - 支持使用`SM2certgen.sh`脚本生成证书，自定义配置参数
* 国标双证书`demo`
* `OpenSSL`的阻塞通信方式

## 国密浏览器

Chromium源码集成国标VPN协议，实现国密通信。实现方式可以通过白名单放行或者自适应TLS和国密VPN协议，对两种实现方式做简单描述：

- 白名单放行-通过配置国密 `URL` 地址来适配国密VPN协议，只有在配置在白名单的网址才能使用过VPN通道
- 自适应协议-根据请求的网址，内核内部自动处理，响应相关的TLS或国密VPN协议

之前在公司见过另一种实现方式，但不推荐使用此方式，具体方法是在原有的HTTP流程注入TLS协议，可以使用OpenSSL或者其它第三方实现国密VPN套件，打断原有的HTTP流程，在通信建立后数据传输前添加国密TLS流程，达到实现HTTPS的方式。

对于上述两种方案，第一种已经实现并在Windows端测试正常，并与国内的国密浏览器做相应测试[中国银行](https://ebssec.boc.cn/boc15/login.html)，性能突出。
目前还有[ovssl](https://sm2test.ovssl.cn/)此服务器可以测试国密VPN，但需要使用具备国密VPN通信的浏览器，否则为TLS协议

