# 简单描述

------

程序为测试工具，用于检测是否可以正常使用国密单向和双向功能，这里仅用于调试。

## 操作说明

静态库在`Ubuntu 14.04.5 LTS`环境下`gcc version 4.8.4 (Ubuntu 4.8.4-2ubuntu1~14.04.4)`编译得到，可以拷贝GmSSL的头文件到指定目录即可编译。

程序编译方式: gcc -g -o client_two client_two.c ./libssl.a ./libcrypto.a -L./  (include文件放置在/usr/local/include目录下，因此这里不需要在添加-I参数)

测试的server_two.c和client_two.c使用的证书为同一份证书，如果修改证书内容，需要调整证书的使用方式:

- 客户端的ca为签发的server的证书，为了完成服务器证书链的校验
- 服务器使用的ca为签发client的证书，为了完成客户端证书链的校验

因此为了方便这里使用了一套证书操作。

程序使用OpenSSL测试国密双证书功能，包含客户端和服务端使用的OpenSSL接口，其中_engine为调用OpenSSL的engine机制实现硬件扩展，国密SKF接口硬件测试demo，目前基于GmSSL的国密SFK硬件测试功能已经完成，测试正常，使用只需要将当前的SKF.so文件配置到安装OpenSSL的lib库下engines-1.1目录。

###  功能列表
- [x] 双向认证
- [ ] 阻塞模式
- [x] ENGINE方式
- [x] 国密双证书
- [ ] 多平台支持


### [Windows/Mac/Linux 全平台客户端]

> 代码在多平台共用，整理完成后上传。
