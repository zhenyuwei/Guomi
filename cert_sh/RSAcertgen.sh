#!/bin/sh

# For a list of supported curves, use "apps/openssl ecparam -list_curves".

# Path to the openssl distribution
OPENSSL_DIR=.
# Path to the openssl program
OPENSSL_CMD=openssl
# Option to find configuration file
OPENSSL_CNF="-config ./openssl.cnf"
# Directory where certificates are stored
CERTS_DIR=./rsaCerts
# Directory where private key files are stored
KEYS_DIR=$CERTS_DIR
# Directory where combo files (containing a certificate and corresponding
# private key together) are stored
COMBO_DIR=$CERTS_DIR
# cat command
CAT=/bin/cat
# rm command
RM=/bin/rm
# mkdir command
MKDIR=/bin/mkdir
# The certificate will expire these many days after the issue date.
DAYS=180
TEST_CA_KEYSIZE=2048
TEST_CA_KEYFILE=CAKEY
TEST_CA_FILE=RSACA
TEST_CA_DN="/C=CN/ST=BJ/L=Beijing/O=RSATest Technology/OU=RSA/CN=Test CA (RSA-sha256)"

TEST_SERVER_KEYSIZE=2048
TEST_SERVER_KEYFILE=SSKEY
TEST_SERVER_FILE=SSign
TEST_SERVER_DN="/C=CN/ST=BJ/L=Beijing/O=RSATest Technology/OU=RSA/CN=192.168.2.30"

TEST_SERVER_ENC_FILE=SEnc
TEST_SERVER_ENC_KEYFILE=SEKEY
TEST_SERVER_ENC_DN="/C=CN/ST=BJ/L=Beijing/O=RSATest Technology/OU=RSA/CN=192.168.2.30"

TEST_CLIENT_KEYSIZE=2048
TEST_SERVER_KEYFILE=CSKEY
TEST_CLIENT_FILE=CSsign
TEST_CLIENT_DN="/C=CN/ST=BJ/L=Beijing/O=RSATest Technology/OU=RSA/CN=192.168.2.30"

TEST_CLIENT_ENC_FILE=CEnc
TEST_CLIENT_ENC_KEYFILE=CEKEY
TEST_CLIENT_ENC_DN="/C=CN/ST=BJ/L=Beijing/O=RSATest Technology/OU=RSA/CN=192.168.2.30"

# Generating an RSA certificate involves the following main steps
# 1. Generating keysize
# 2. Generating a certificate request
# 3. Signing the certificate request 
# 4. [Optional] One can combine the cert and private key into a single
#    file and also delete the certificate request

$MKDIR -p $CERTS_DIR
$MKDIR -p $KEYS_DIR
$MKDIR -p $COMBO_DIR

# Generate init data
touch index.txt serial
chmod 666 index.txt serial
echo 01 >  serial

echo "Generating self-signed CA certificate (on keysize $TEST_CA_KEYSIZE)"
echo "==============================================================="
$OPENSSL_CMD genrsa -out $KEYS_DIR/$TEST_CA_KEYFILE.key.pem $TEST_SERVER_KEYSIZE

# Generate a self certificate
openssl req -new -x509 -days $DAYS $OPENSSL_CNF -subj "$TEST_CA_DN" \
	-key $KEYS_DIR/$TEST_CA_KEYFILE.key.pem -out $CERTS_DIR/$TEST_CA_FILE.cert.pem 


# Display the certificate
$OPENSSL_CMD x509 -in $CERTS_DIR/$TEST_CA_FILE.cert.pem -text

# Place the certificate and key in a common file
$OPENSSL_CMD x509 -in $CERTS_DIR/$TEST_CA_FILE.cert.pem -issuer -subject \
	 > $COMBO_DIR/$TEST_CA_FILE.pem
$CAT $KEYS_DIR/$TEST_CA_KEYFILE.key.pem >> $COMBO_DIR/$TEST_CA_FILE.pem


echo "GENERATING A TEST SERVER CERTIFICATE"
echo "=========================================================================="
$OPENSSL_CMD genrsa -out $KEYS_DIR/$TEST_SERVER_KEYFILE.key.pem $TEST_SERVER_KEYSIZE

# Generate a new certificate request in $TEST_SERVER_FILE.req.pem.
$OPENSSL_CMD req -new -key $KEYS_DIR/$TEST_SERVER_KEYFILE.key.pem \
	-subj "$TEST_SERVER_DN" -out $CERTS_DIR/$TEST_SERVER_FILE.req.pem $OPENSSL_CNF 
	
# Sign the certificate request in $TEST_SERVER_FILE.req.pem 
$OPENSSL_CMD x509 -req -days $DAYS \
    -in $CERTS_DIR/$TEST_SERVER_FILE.req.pem \
    -CA $CERTS_DIR/$TEST_CA_FILE.cert.pem \
    -CAkey $KEYS_DIR/$TEST_CA_KEYFILE.key.pem \
	-extfile $OPENSSL_DIR/openssl.cnf \
	-extensions v3_req \
    -out $CERTS_DIR/$TEST_SERVER_FILE.cert.pem -CAcreateserial

# Display the certificate 
$OPENSSL_CMD x509 -in $CERTS_DIR/$TEST_SERVER_FILE.cert.pem -text

# Place the certificate and key in a common file
$OPENSSL_CMD x509 -in $CERTS_DIR/$TEST_SERVER_FILE.cert.pem -issuer -subject \
	 > $COMBO_DIR/$TEST_SERVER_FILE.pem
$CAT $KEYS_DIR/$TEST_SERVER_KEYFILE.key.pem >> $COMBO_DIR/$TEST_SERVER_FILE.pem

# Remove the cert request file (no longer needed)
$RM $CERTS_DIR/$TEST_SERVER_FILE.req.pem


echo "	GENERATING A TEST SERVER ENCRYPT CERTIFICATE"
echo "  ==================================================================================="
$OPENSSL_CMD genrsa -out $KEYS_DIR/$TEST_SERVER_ENC_KEYFILE.key.pem $TEST_SERVER_KEYSIZE

# Generate a new certificate request in $TEST_SERVER_FILE.req.pem.
$OPENSSL_CMD req -new -key $KEYS_DIR/$TEST_SERVER_ENC_KEYFILE.key.pem \
	-subj "$TEST_SERVER_DN" -out $CERTS_DIR/$TEST_SERVER_ENC_FILE.req.pem $OPENSSL_CNF 

# Sign the certificate request in $TEST_SERVER_FILE.req.pem 
$OPENSSL_CMD x509 -req -days $DAYS \
    -in $CERTS_DIR/$TEST_SERVER_ENC_FILE.req.pem \
    -CA $CERTS_DIR/$TEST_CA_FILE.cert.pem \
    -CAkey $KEYS_DIR/$TEST_CA_KEYFILE.key.pem \
	-extfile $OPENSSL_DIR/openssl.cnf \
	-extensions v3enc_req \
    -out $CERTS_DIR/$TEST_SERVER_ENC_FILE.cert.pem -CAcreateserial

# Display the certificate 
$OPENSSL_CMD x509 -in $CERTS_DIR/$TEST_SERVER_ENC_FILE.cert.pem -text

# Place the certificate and key in a common file
$OPENSSL_CMD x509 -in $CERTS_DIR/$TEST_SERVER_ENC_FILE.cert.pem -issuer -subject \
	 > $COMBO_DIR/$TEST_SERVER_ENC_FILE.pem
$CAT $KEYS_DIR/$TEST_SERVER_ENC_KEYFILE.key.pem >> $COMBO_DIR/$TEST_SERVER_ENC_FILE.pem

# Remove the cert request file (no longer needed)
$RM $CERTS_DIR/$TEST_SERVER_ENC_FILE.req.pem


echo "GENERATING A TEST CLIENT CERTIFICATE "
echo "=========================================================================="
$OPENSSL_CMD genrsa -out $KEYS_DIR/$TEST_CLIENT_KEYFILE.key.pem $TEST_CLIENT_KEYSIZE

# Generate a new certificate request in $TEST_CLIENT_FILE.req.pem. 
$OPENSSL_CMD req -new -key $KEYS_DIR/$TEST_CLIENT_KEYFILE.key.pem \
	-subj "$TEST_SERVER_DN" -out $CERTS_DIR/$TEST_CLIENT_FILE.req.pem $OPENSSL_CNF 

# Sign the certificate request in $TEST_CLIENT_FILE.req.pem 
$OPENSSL_CMD x509 -req -days $DAYS \
    -in $CERTS_DIR/$TEST_CLIENT_FILE.req.pem \
    -CA $CERTS_DIR/$TEST_CA_FILE.cert.pem \
    -CAkey $KEYS_DIR/$TEST_CA_KEYFILE.key.pem \
	-extfile $OPENSSL_DIR/openssl.cnf \
	-extensions v3_req \
    -out $CERTS_DIR/$TEST_CLIENT_FILE.cert.pem -CAcreateserial

# Display the certificate 
$OPENSSL_CMD x509 -in $CERTS_DIR/$TEST_CLIENT_FILE.cert.pem -text

# Place the certificate and key in a common file
$OPENSSL_CMD x509 -in $CERTS_DIR/$TEST_CLIENT_FILE.cert.pem -issuer -subject \
	 > $COMBO_DIR/$TEST_CLIENT_FILE.pem
$CAT $KEYS_DIR/$TEST_CLIENT_KEYFILE.key.pem >> $COMBO_DIR/$TEST_CLIENT_FILE.pem

# Remove the cert request file (no longer needed)
$RM $CERTS_DIR/$TEST_CLIENT_FILE.req.pem


echo "	GENERATING A TEST CLIENT ENCRYPT CERTIFICATE (on elliptic curve $TEST_CLIENT_CURVE)"
echo "	==================================================================================="
$OPENSSL_CMD genrsa -out $KEYS_DIR/$TEST_CLIENT_ENC_KEYFILE.key.pem $TEST_CLIENT_KEYSIZE

# Generate a new certificate request in $TEST_CLIENT_FILE.req.pem. 
$OPENSSL_CMD req -new -key $KEYS_DIR/$TEST_CLIENT_ENC_KEYFILE.key.pem \
	-subj "$TEST_SERVER_DN" -out $CERTS_DIR/$TEST_CLIENT_ENC_FILE.req.pem $OPENSSL_CNF 
	
# Sign the certificate request in $TEST_CLIENT_FILE.req.pem 
$OPENSSL_CMD x509 -req -days $DAYS \
    -in $CERTS_DIR/$TEST_CLIENT_ENC_FILE.req.pem \
    -CA $CERTS_DIR/$TEST_CA_FILE.cert.pem \
    -CAkey $KEYS_DIR/$TEST_CA_KEYFILE.key.pem \
	-extfile $OPENSSL_DIR/openssl.cnf \
	-extensions v3enc_req \
    -out $CERTS_DIR/$TEST_CLIENT_ENC_FILE.cert.pem -CAcreateserial

# Display the certificate 
$OPENSSL_CMD x509 -in $CERTS_DIR/$TEST_CLIENT_ENC_FILE.cert.pem -text

# Place the certificate and key in a common file
$OPENSSL_CMD x509 -in $CERTS_DIR/$TEST_CLIENT_ENC_FILE.cert.pem -issuer -subject \
	 > $COMBO_DIR/$TEST_CLIENT_ENC_FILE.pem
$CAT $KEYS_DIR/$TEST_CLIENT_ENC_KEYFILE.key.pem >> $COMBO_DIR/$TEST_CLIENT_ENC_FILE.pem

# Remove the cert request file (no longer needed)
$RM $CERTS_DIR/$TEST_CLIENT_ENC_FILE.req.pem


