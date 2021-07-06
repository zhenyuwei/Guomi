#!/bin/sh

# For a list of supported curves, use "apps/openssl ecparam -list_curves".

# Path to the openssl distribution
OPENSSL_DIR=.
# Path to the openssl program
#OPENSSL_CMD=openssl
OPENSSL_CMD=openssl
# Option to find configuration file
OPENSSL_CNF="-config ./openssl.cnf"
# Directory where certificates are stored
CERTS_DIR=./demoCA
# Directory where key are stored
CAKEY_DIR=./demoCA/private
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
# MV command
MVDIR=/bin/mv
# CP command
CPDIR=/bin/cp
# touch command
TOUCHDIR=/bin/touch

# The certificate will expire these many days after the issue date.
DAYS=700
TEST_CA=SM2
TEST_CA_CURVE=SM2
TEST_CA_FILE=CA
TEST_CA_DN="/C=CN/ST=BJ/L=Beijing/O=Beijing SM2Test/OU=SM2Test/CN=Test CA (SM2)"

TEST_SERVER_CURVE=SM2
TEST_SERVER_FILE=SS
TEST_SERVER_DN="/C=CN/ST=BJ/L=Beijing/O=Beijing SM2Test/OU=SM2Test/CN=192.168.2.30"

TEST_SERVER_ENC_FILE=SE
TEST_SERVER_ENC_DN="/C=CN/ST=BJ/L=Beijing/O=Beijing SM2Test/OU=SM2Test/CN=192.168.2.30"

TEST_CLIENT_CURVE=SM2
TEST_CLIENT_FILE=CS
TEST_CLIENT_DN="/C=CN/ST=BJ/L=Beijing/O=Beijing SM2Test/OU=SM2Test/CN=192.168.2.30"

TEST_CLIENT_ENC_FILE=CE
TEST_CLIENT_ENC_DN="/C=CN/ST=BJ/L=Beijing/O=Beijing SM2Test/OU=SM2Test/CN=192.168.2.30"

# Generating an EC certificate involves the following main steps
# 1. Generating curve parameters (if needed)
# 2. Generating a certificate request
# 3. Signing the certificate request 
# 4. [Optional] One can combine the cert and private key into a single
#    file and also delete the certificate request

$MKDIR -p $CERTS_DIR
$MKDIR -p $KEYS_DIR
$MKDIR -p $COMBO_DIR
$MKDIR -p $CAKEY_DIR

# create file index.txt and serial
$TOUCHDIR $CERTS_DIR/index.txt
$TOUCHDIR $CERTS_DIR/serial
$TOUCHDIR $CERTS_DIR/index.txt.attr
$TOUCHDIR $CERTS_DIR/crlnumber
echo "01" > $CERTS_DIR/serial

echo "Generating self-signed CA certificate (on curve $TEST_CA_CURVE)"
echo "==============================================================="
$OPENSSL_CMD genpkey -algorithm $TEST_CA_CURVE -out $TEST_CA.pem

# Generate a new certificate request in $TEST_CA_FILE.req.pem. A 
# new ecdsa (actually ECC) key pair is generated on the parameters in
# $TEST_CA.pem and the private key is saved in $TEST_CA_FILE.key.pem
# WARNING: By using the -nodes option, we force the private key to be 
# stored in the clear (rather than encrypted with a password).
$OPENSSL_CMD req -config ./CA.cnf -nodes -subj "$TEST_CA_DN" \
    -keyout $KEYS_DIR/$TEST_CA_FILE.key.pem \
    -new -key $TEST_CA.pem -new \
    -out $CERTS_DIR/$TEST_CA_FILE.req.pem -sm3

# Sign the certificate request in $TEST_CA_FILE.req.pem using the
# private key in $TEST_CA_FILE.key.pem and include the CA extension.
# Make the certificate valid for 1500 days from the time of signing.
# The certificate is written into $TEST_CA_FILE.cert.pem
$OPENSSL_CMD x509 -req -days $DAYS \
    -in $CERTS_DIR/$TEST_CA_FILE.req.pem \
    -extfile $OPENSSL_DIR/openssl.cnf \
    -extensions v3_ca \
    -signkey $KEYS_DIR/$TEST_CA_FILE.key.pem \
    -out $CERTS_DIR/$TEST_CA_FILE.cert.pem -sm3

# Display the certificate
$OPENSSL_CMD x509 -in $CERTS_DIR/$TEST_CA_FILE.cert.pem -text

# Place the certificate and key in a common file
$OPENSSL_CMD x509 -in $CERTS_DIR/$TEST_CA_FILE.cert.pem -issuer -subject \
	 > $COMBO_DIR/$TEST_CA_FILE.pem
$CAT $KEYS_DIR/$TEST_CA_FILE.key.pem >> $COMBO_DIR/$TEST_CA_FILE.pem

# move key to private file and rename cakey.pem
$CPDIR $KEYS_DIR/$TEST_CA_FILE.key.pem $CAKEY_DIR/cakey.pem
$CPDIR $COMBO_DIR/$TEST_CA_FILE.pem $COMBO_DIR/cacert.pem

# Remove the cert request file (no longer needed)
$RM $CERTS_DIR/$TEST_CA_FILE.req.pem

echo "GENERATING A TEST SERVER CERTIFICATE (on elliptic curve $TEST_SERVER_CURVE)"
echo "=========================================================================="
# Generate a new certificate request in $TEST_SERVER_FILE.req.pem. A 
# new ecdsa (actually ECC) key pair is generated on the parameters in
# $TEST_SERVER_CURVE.pem and the private key is saved in 
# $TEST_SERVER_FILE.key.pem
# WARNING: By using the -nodes option, we force the private key to be 
# stored in the clear (rather than encrypted with a password).
$OPENSSL_CMD req -config eccsignuser.cnf -nodes -subj "$TEST_SERVER_DN" \
    -keyout $KEYS_DIR/$TEST_SERVER_FILE.key.pem \
    -new -key $TEST_SERVER_CURVE.pem -new \
    -out $CERTS_DIR/$TEST_SERVER_FILE.req.pem -sm3

# Sign the certificate request in $TEST_SERVER_FILE.req.pem using the
# CA certificate in $TEST_CA_FILE.cert.pem and the CA private key in
# $TEST_CA_FILE.key.pem. Since we do not have an existing serial number
# file for this CA, create one. Make the certificate valid for $DAYS days
# from the time of signing. The certificate is written into 
# $TEST_SERVER_FILE.cert.pem
$OPENSSL_CMD x509 -req -days $DAYS \
    -in $CERTS_DIR/$TEST_SERVER_FILE.req.pem \
    -CA $CERTS_DIR/$TEST_CA_FILE.cert.pem \
    -CAkey $KEYS_DIR/$TEST_CA_FILE.key.pem \
	-extfile $OPENSSL_DIR/openssl.cnf \
	-extensions v3_req \
    -out $CERTS_DIR/$TEST_SERVER_FILE.cert.pem -CAcreateserial -sm3

# Display the certificate 
$OPENSSL_CMD x509 -in $CERTS_DIR/$TEST_SERVER_FILE.cert.pem -text

# Place the certificate and key in a common file
$OPENSSL_CMD x509 -in $CERTS_DIR/$TEST_SERVER_FILE.cert.pem -issuer -subject \
	 > $COMBO_DIR/$TEST_SERVER_FILE.pem
$CAT $KEYS_DIR/$TEST_SERVER_FILE.key.pem >> $COMBO_DIR/$TEST_SERVER_FILE.pem

# Verify cert
$OPENSSL_CMD verify -CAfile $COMBO_DIR/$TEST_CA_FILE.pem $COMBO_DIR/$TEST_SERVER_FILE.pem

# Remove the cert request file (no longer needed)
$RM $CERTS_DIR/$TEST_SERVER_FILE.req.pem

echo "	GENERATING A TEST SERVER ENCRYPT CERTIFICATE (on elliptic curve $TEST_SERVER_CURVE)"
echo "  ==================================================================================="
# Generate a new certificate request in $TEST_SERVER_FILE.req.pem. A 
# new ecdsa (actually ECC) key pair is generated on the parameters in
# $TEST_SERVER_CURVE.pem and the private key is saved in 
# $TEST_SERVER_FILE.key.pem
# WARNING: By using the -nodes option, we force the private key to be 
# stored in the clear (rather than encrypted with a password).
$OPENSSL_CMD req -config eccencuser.cnf -nodes -subj "$TEST_SERVER_ENC_DN" \
    -keyout $KEYS_DIR/$TEST_SERVER_ENC_FILE.key.pem \
    -new -key $TEST_SERVER_CURVE.pem -new \
    -out $CERTS_DIR/$TEST_SERVER_ENC_FILE.req.pem -sm3

# Sign the certificate request in $TEST_SERVER_FILE.req.pem using the
# CA certificate in $TEST_CA_FILE.cert.pem and the CA private key in
# $TEST_CA_FILE.key.pem. Since we do not have an existing serial number
# file for this CA, create one. Make the certificate valid for $DAYS days
# from the time of signing. The certificate is written into 
# $TEST_SERVER_FILE.cert.pem
$OPENSSL_CMD x509 -req -days $DAYS \
    -in $CERTS_DIR/$TEST_SERVER_ENC_FILE.req.pem \
    -CA $CERTS_DIR/$TEST_CA_FILE.cert.pem \
    -CAkey $KEYS_DIR/$TEST_CA_FILE.key.pem \
	-extfile $OPENSSL_DIR/openssl.cnf \
	-extensions v3enc_req \
    -out $CERTS_DIR/$TEST_SERVER_ENC_FILE.cert.pem -CAcreateserial -sm3

# Display the certificate 
$OPENSSL_CMD x509 -in $CERTS_DIR/$TEST_SERVER_ENC_FILE.cert.pem -text

# Place the certificate and key in a common file
$OPENSSL_CMD x509 -in $CERTS_DIR/$TEST_SERVER_ENC_FILE.cert.pem -issuer -subject \
	 > $COMBO_DIR/$TEST_SERVER_ENC_FILE.pem
$CAT $KEYS_DIR/$TEST_SERVER_ENC_FILE.key.pem >> $COMBO_DIR/$TEST_SERVER_ENC_FILE.pem

# Verify cert
$OPENSSL_CMD verify -CAfile $COMBO_DIR/$TEST_CA_FILE.pem $COMBO_DIR/$TEST_SERVER_ENC_FILE.pem

# Remove the cert request file (no longer needed)
$RM $CERTS_DIR/$TEST_SERVER_ENC_FILE.req.pem



echo "GENERATING A TEST CLIENT CERTIFICATE (on elliptic curve $TEST_CLIENT_CURVE)"
echo "=========================================================================="
# Generate a new certificate request in $TEST_CLIENT_FILE.req.pem. A 
# new ecdsa (actually ECC) key pair is generated on the parameters in
# $TEST_CLIENT_CURVE.pem and the private key is saved in 
# $TEST_CLIENT_FILE.key.pem
# WARNING: By using the -nodes option, we force the private key to be 
# stored in the clear (rather than encrypted with a password).
$OPENSSL_CMD req -config eccsignuser.cnf -nodes -subj "$TEST_CLIENT_DN" \
	     -keyout $KEYS_DIR/$TEST_CLIENT_FILE.key.pem \
	     -new -key $TEST_CLIENT_CURVE.pem -new \
	     -out $CERTS_DIR/$TEST_CLIENT_FILE.req.pem -sm3

# Sign the certificate request in $TEST_CLIENT_FILE.req.pem using the
# CA certificate in $TEST_CA_FILE.cert.pem and the CA private key in
# $TEST_CA_FILE.key.pem. Since we do not have an existing serial number
# file for this CA, create one. Make the certificate valid for $DAYS days
# from the time of signing. The certificate is written into 
# $TEST_CLIENT_FILE.cert.pem
$OPENSSL_CMD x509 -req -days $DAYS \
    -in $CERTS_DIR/$TEST_CLIENT_FILE.req.pem \
    -CA $CERTS_DIR/$TEST_CA_FILE.cert.pem \
    -CAkey $KEYS_DIR/$TEST_CA_FILE.key.pem \
	-extfile $OPENSSL_DIR/openssl.cnf \
	-extensions v3_req \
    -out $CERTS_DIR/$TEST_CLIENT_FILE.cert.pem -CAcreateserial -sm3

# Display the certificate 
$OPENSSL_CMD x509 -in $CERTS_DIR/$TEST_CLIENT_FILE.cert.pem -text

# Place the certificate and key in a common file
$OPENSSL_CMD x509 -in $CERTS_DIR/$TEST_CLIENT_FILE.cert.pem -issuer -subject \
	 > $COMBO_DIR/$TEST_CLIENT_FILE.pem
$CAT $KEYS_DIR/$TEST_CLIENT_FILE.key.pem >> $COMBO_DIR/$TEST_CLIENT_FILE.pem

# Verify cert
$OPENSSL_CMD verify -CAfile $COMBO_DIR/$TEST_CA_FILE.pem $COMBO_DIR/$TEST_CLIENT_FILE.pem

# Remove the cert request file (no longer needed)
$RM $CERTS_DIR/$TEST_CLIENT_FILE.req.pem


echo "	GENERATING A TEST CLIENT ENCRYPT CERTIFICATE (on elliptic curve $TEST_CLIENT_CURVE)"
echo "	==================================================================================="
# Generate a new certificate request in $TEST_CLIENT_FILE.req.pem. A 
# new ecdsa (actually ECC) key pair is generated on the parameters in
# $TEST_CLIENT_CURVE.pem and the private key is saved in 
# $TEST_CLIENT_FILE.key.pem
# WARNING: By using the -nodes option, we force the private key to be 
# stored in the clear (rather than encrypted with a password).
$OPENSSL_CMD req -config eccencuser.cnf -nodes -subj "$TEST_CLIENT_ENC_DN" \
	     -keyout $KEYS_DIR/$TEST_CLIENT_ENC_FILE.key.pem \
	     -new -key $TEST_CLIENT_CURVE.pem -new \
	     -out $CERTS_DIR/$TEST_CLIENT_ENC_FILE.req.pem -sm3

# Sign the certificate request in $TEST_CLIENT_FILE.req.pem using the
# CA certificate in $TEST_CA_FILE.cert.pem and the CA private key in
# $TEST_CA_FILE.key.pem. Since we do not have an existing serial number
# file for this CA, create one. Make the certificate valid for $DAYS days
# from the time of signing. The certificate is written into 
# $TEST_CLIENT_FILE.cert.pem
$OPENSSL_CMD x509 -req -days $DAYS \
    -in $CERTS_DIR/$TEST_CLIENT_ENC_FILE.req.pem \
    -CA $CERTS_DIR/$TEST_CA_FILE.cert.pem \
    -CAkey $KEYS_DIR/$TEST_CA_FILE.key.pem \
	-extfile $OPENSSL_DIR/openssl.cnf \
	-extensions v3enc_req \
    -out $CERTS_DIR/$TEST_CLIENT_ENC_FILE.cert.pem -CAcreateserial -sm3

# Display the certificate 
$OPENSSL_CMD x509 -in $CERTS_DIR/$TEST_CLIENT_ENC_FILE.cert.pem -text

# Place the certificate and key in a common file
$OPENSSL_CMD x509 -in $CERTS_DIR/$TEST_CLIENT_ENC_FILE.cert.pem -issuer -subject \
	 > $COMBO_DIR/$TEST_CLIENT_ENC_FILE.pem
$CAT $KEYS_DIR/$TEST_CLIENT_ENC_FILE.key.pem >> $COMBO_DIR/$TEST_CLIENT_ENC_FILE.pem

# Verify cert
$OPENSSL_CMD verify -CAfile $COMBO_DIR/$TEST_CA_FILE.pem $COMBO_DIR/$TEST_CLIENT_ENC_FILE.pem

# Remove the cert request file (no longer needed)
$RM $CERTS_DIR/$TEST_CLIENT_ENC_FILE.req.pem

echo "  GENERATING A TEST CERTIFICATE FOR REVOKE (on elliptic curve $TEST_CLIENT_CURVE)"
echo "  ==================================================================================="
# Generate a new certificate request in $TEST_CLIENT_FILE.req.pem. A
# new ecdsa (actually ECC) key pair is generated on the parameters in
# $TEST_CLIENT_CURVE.pem and the private key is saved in
# $TEST_CLIENT_FILE.key.pem
# WARNING: By using the -nodes option, we force the private key to be
# stored in the clear (rather than encrypted with a password).
$OPENSSL_CMD req -config eccencuser.cnf -nodes -subj "$TEST_CLIENT_ENC_DN" \
             -keyout $KEYS_DIR/$TEST_CLIENT_ENC_FILE.key.pem1 \
             -new -key $TEST_CLIENT_CURVE.pem -new \
             -out $CERTS_DIR/$TEST_CLIENT_ENC_FILE.req.pem1 -sm3

# Sign the certificate request in $TEST_CLIENT_FILE.req.pem using the
# CA certificate in $TEST_CA_FILE.cert.pem and the CA private key in
# $TEST_CA_FILE.key.pem. Since we do not have an existing serial number
# file for this CA, create one. Make the certificate valid for $DAYS days
# from the time of signing. The certificate is written into
# $TEST_CLIENT_FILE.cert.pem
$OPENSSL_CMD x509 -req -days $DAYS \
    -in $CERTS_DIR/$TEST_CLIENT_ENC_FILE.req.pem1 \
    -CA $CERTS_DIR/$TEST_CA_FILE.cert.pem \
    -CAkey $KEYS_DIR/$TEST_CA_FILE.key.pem \
        -extfile $OPENSSL_DIR/openssl.cnf \
        -extensions v3enc_req \
    -out $CERTS_DIR/$TEST_CLIENT_ENC_FILE.cert.pem1 -CAcreateserial -sm3

# Display the certificate
$OPENSSL_CMD x509 -in $CERTS_DIR/$TEST_CLIENT_ENC_FILE.cert.pem1 -text

# Place the certificate and key in a common file
$OPENSSL_CMD x509 -in $CERTS_DIR/$TEST_CLIENT_ENC_FILE.cert.pem1 -issuer -subject \
         > $COMBO_DIR/$TEST_CLIENT_ENC_FILE.pem1
$CAT $KEYS_DIR/$TEST_CLIENT_ENC_FILE.key.pem1 >> $COMBO_DIR/$TEST_CLIENT_ENC_FILE.pem1

# Verify cert
$OPENSSL_CMD verify -CAfile $COMBO_DIR/$TEST_CA_FILE.pem $COMBO_DIR/$TEST_CLIENT_ENC_FILE.pem1

# Remove the cert request file (no longer needed)
$RM $CERTS_DIR/$TEST_CLIENT_ENC_FILE.req.pem1

# Revoke cert
$OPENSSL_CMD ca -config $OPENSSL_DIR/openssl.cnf -revoke $COMBO_DIR/$TEST_CLIENT_ENC_FILE.pem1

# i want to export crl file
$OPENSSL_CMD ca -config openssl.cnf -gencrl -out ca.crl.pem

# Verfiy Cert chain
echo "Verify $TEST_SERVER_FILE use $TEST_CA_FILE.cert.pem"
$OPENSSL_CMD verify -CAfile $CERTS_DIR/$TEST_CA_FILE.cert.pem $CERTS_DIR/$TEST_SERVER_FILE.pem
echo "Verify $TEST_SERVER_ENC_FILE use $TEST_CA_FILE.cert.pem"
$OPENSSL_CMD verify -CAfile $CERTS_DIR/$TEST_CA_FILE.cert.pem $CERTS_DIR/$TEST_SERVER_ENC_FILE.pem
echo "Verify $TEST_CLIENT_FILE use $TEST_CA_FILE.cert.pem"
$OPENSSL_CMD verify -CAfile $CERTS_DIR/$TEST_CA_FILE.cert.pem $CERTS_DIR/$TEST_CLIENT_FILE.pem
echo "Verify $TEST_CLIENT_ENC_FILE use $TEST_CA_FILE.cert.pem"
$OPENSSL_CMD verify -CAfile $CERTS_DIR/$TEST_CA_FILE.cert.pem $CERTS_DIR/$TEST_CLIENT_ENC_FILE.pem

