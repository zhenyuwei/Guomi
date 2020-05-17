# 脚本说明

RSA/SM2证书生成工具，使用`OpenSSL/GmSSL`可以正常生成证书。

## RSA证书

`RSAcertgen.sh` 生成RSA证书，证书配置参数使用当前目录的`openssl.cnf`文件，调整配置请自行修改。

TEST_CA_DN、TEST_SERVER_DN、TEST_SERVER_ENC_DN等字段对应证书的使用者(issuer)信息，根据需求修改。

修改参数包括default_md、keyUsage以及alt_names配置项。

配置项说明:
  - default_md:默认使用的哈希算法，推荐使用sha256
  - keyUsage:扩展字段中的密钥用法，RSA证书推荐使用nonRepudiation, digitalSignature, keyEncipherment这三种
  - alt_names:扩展字段的使用者可选名称


## SM2证书 

**《GM/T 0024-2014 SSL VPN技术规范》** 中定义了双证书模式，包括加密证书和签名这里。这里使用不同的cnf配置文件来调整证书的keyUsage字段，决定哪种为加密证书和签名证书。

国密证书使用的签名算法为sm3，在每个req文件后指定了签名算法，也可以在cnf中指定。不推荐生成sha系列的国密证书，此证书目前不适用**《GM/T 0024-2014 SSL VPN技术规范》**。