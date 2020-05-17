#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <sys/socket.h>
#include <resolv.h>
#include <stdlib.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <openssl/ssl.h>
#include <openssl/err.h>

#define MAXBUF 1024

#define CA_FILE                 "ca.pem"
#define CLIENT_KEY              "svr.pem"
#define CLIENT_CERT         	"svr.pem"
#define CLIENT_ENC_KEY			"svrenc.pem"
#define CLIENT_ENC_CERT			"svrenc.pem"

void ShowCerts(SSL * ssl)
{
    X509 *cert;
    char *line;
    cert = SSL_get_peer_certificate(ssl);
    if (cert != NULL) {
        printf("数字证书信息:\n");
        line = X509_NAME_oneline(X509_get_subject_name(cert), 0, 0);
        printf("证书: %s\n", line);
        free(line);
        line = X509_NAME_oneline(X509_get_issuer_name(cert), 0, 0);
        printf("颁发者: %s\n", line);
        free(line);
        X509_free(cert);
    } else {
        printf("无证书信息！\n");
    }
}

int main(int argc, char **argv)
{
    int sockfd, len;
    struct sockaddr_in dest;
    char buffer[MAXBUF + 1];
    SSL_CTX *ctx;
    SSL *ssl;
    const SSL_METHOD *method;

    if (argc != 3) {
        printf("参数格式错误！正确用法如下：\n\t\t%s IP地址 端口\n\t比如:\t%s 127.0.0.1 80\n此程序用来从某个"
                "IP 地址的服务器某个端口接收最多 MAXBUF 个字节的消息", argv[0], argv[0]);
        exit(0);
    }

/* Init SSL info */
    SSL_library_init();
    SSL_load_error_strings();
    OpenSSL_add_all_algorithms();  
    method = GMTLS_client_method(); /* set gmssl protocal */
    ctx = SSL_CTX_new(method);

    if (!ctx) {
        printf("create ctx is failed.\n");
    }

    const char * cipher_list = "SM2-WITH-SMS4-SM3:SM2DHE-WITH-SMS4-SM3";
    if (SSL_CTX_set_cipher_list(ctx, cipher_list) == 0) { /* set cipher suit in clienthello */
        SSL_CTX_free(ctx);
        printf("Failed to set cipher list: %s", cipher_list);
    }

    /*设置会话的握手方式*/ 
    //SSL_CTX_set_verify(ctx, SSL_VERIFY_PEER | SSL_VERIFY_FAIL_IF_NO_PEER_CERT, 0);

    /*加载CA FILE*/
    if (SSL_CTX_load_verify_locations(ctx, CA_FILE, 0) != 1) {
        SSL_CTX_free(ctx);
        printf("Failed to load CA file %s", CA_FILE);
    }
    if (SSL_CTX_set_default_verify_paths(ctx) != 1) {
        SSL_CTX_free(ctx);
        printf("Call to SSL_CTX_set_default_verify_paths failed");
    }
    /*加载客户端签名证书*/
    if (SSL_CTX_use_certificate_file(ctx, CLIENT_CERT, SSL_FILETYPE_PEM) != 1) {
        SSL_CTX_free(ctx);
        printf("Failed to load client certificate from %s", CLIENT_KEY);
    }
    /*加载客户端签名私钥*/
    if (SSL_CTX_use_PrivateKey_file(ctx, CLIENT_KEY, SSL_FILETYPE_PEM) != 1) {
        SSL_CTX_free(ctx);
        printf("Failed to load client private key from %s", CLIENT_KEY);
    }
    /*验证私钥*/
    if (SSL_CTX_check_private_key(ctx) != 1) {
        SSL_CTX_free(ctx);
        printf("SSL_CTX_check_private_key failed");
    }

    /*加载客户端加密证书*/
    if (SSL_CTX_use_certificate_file(ctx, CLIENT_ENC_CERT, SSL_FILETYPE_PEM) != 1) {
        SSL_CTX_free(ctx);
        printf("Failed to load client certificate from %s", CLIENT_KEY);
    }
    /*加载客户端加密私钥*/
    if (SSL_CTX_use_PrivateKey_file(ctx, CLIENT_ENC_KEY, SSL_FILETYPE_PEM) != 1) {
        SSL_CTX_free(ctx);
        printf("Failed to load client private key from %s", CLIENT_KEY);
    }
    /*验证私钥*/
    if (SSL_CTX_check_private_key(ctx) != 1) {
        SSL_CTX_free(ctx);
        printf("SSL_CTX_check_private_key failed");
    }

    /*处理握手多次*/  
    SSL_CTX_set_mode(ctx, SSL_MODE_AUTO_RETRY); 

    if ((sockfd = socket(AF_INET, SOCK_STREAM, 0)) < 0) {
        perror("Socket");
        exit(errno);
    }

    bzero(&dest, sizeof(dest));
    dest.sin_family = AF_INET;
    dest.sin_port = htons(atoi(argv[2]));
    if (inet_aton(argv[1], (struct in_addr *) &dest.sin_addr.s_addr) == 0) {
        perror(argv[0]);
        exit(errno);
    }

    if (connect(sockfd, (struct sockaddr *) &dest, sizeof(dest)) != 0) {
        perror("Connect ");
        exit(errno);
    }

    /*创建SSL*/
    ssl = SSL_new(ctx);
    if (ssl == NULL) {
        printf("SSL_new error.\n");
    }
    /*将fd添加到ssl层*/
    SSL_set_fd(ssl, sockfd);
    if (SSL_connect(ssl) == -1) {
        printf("SSL_connect fail.\n");
        ERR_print_errors_fp(stderr);
    } else {
        printf("Connected with %s encryption\n", SSL_get_cipher(ssl));
        //ShowCerts(ssl);
    }

    bzero(buffer, MAXBUF + 1);
    strcpy(buffer, "from client->server");

    len = SSL_write(ssl, buffer, strlen(buffer));
    if (len < 0) {
        printf("消息'%s'发送失败！错误代码是%d，错误信息是'%s'\n", buffer, errno, strerror(errno));
    } else {
        printf("消息'%s'发送成功，共发送了%d个字节！\n", buffer, len);
    }

    bzero(buffer, MAXBUF + 1);
    len = SSL_read(ssl, buffer, MAXBUF);
    if (len > 0) {
        printf("接收消息成功:'%s'，共%d个字节的数据\n", buffer, len);
    } else {
        printf("消息接收失败！错误代码是%d，错误信息是'%s'\n", errno, strerror(errno));
        goto finish;
    }
	
finish:
    SSL_shutdown(ssl);
    SSL_free(ssl);
    close(sockfd);
    SSL_CTX_free(ctx);
    return 0;
}
