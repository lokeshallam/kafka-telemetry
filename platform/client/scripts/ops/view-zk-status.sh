#!/bin/bash

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh $1
[ $? -eq 1 ] && echo "could not setup environment variables" && exit

# Zookeeper Commands: https://zookeeper.apache.org/doc/r3.5.9/zookeeperAdmin.html#sc_4lw
ZK_CMD1="stat"
ZK_CMD2="dirs"
echo ""
echo "************************************"
echo " zoo1"
echo "************************************"
echo -e "$ZK_CMD1" | openssl 2>&1 s_client -quiet -connect $ZOO1_URL -CAfile $KEYSTORE_DIR/intermediate.crt -cert $KEYSTORE_DIR/client.${DOMAIN}_cert.pem -key $KEYSTORE_DIR/client.${DOMAIN}_key.pem -pass pass:$KEYSTORE_PASSWORD
echo -e "$ZK_CMD2" | openssl 2>&1 s_client -quiet -connect $ZOO1_URL -CAfile $KEYSTORE_DIR/intermediate.crt -cert $KEYSTORE_DIR/client.${DOMAIN}_cert.pem -key $KEYSTORE_DIR/client.${DOMAIN}_key.pem -pass pass:$KEYSTORE_PASSWORD
echo ""
echo "************************************"
echo " zoo2"
echo "************************************"
echo -e "$ZK_CMD1" | openssl 2>&1 s_client -quiet -connect $ZOO2_URL -CAfile $KEYSTORE_DIR/intermediate.crt -cert $KEYSTORE_DIR/client.${DOMAIN}_cert.pem -key $KEYSTORE_DIR/client.${DOMAIN}_key.pem -pass pass:$KEYSTORE_PASSWORD
echo -e "$ZK_CMD2" | openssl 2>&1 s_client -quiet -connect $ZOO2_URL -CAfile $KEYSTORE_DIR/intermediate.crt -cert $KEYSTORE_DIR/client.${DOMAIN}_cert.pem -key $KEYSTORE_DIR/client.${DOMAIN}_key.pem -pass pass:$KEYSTORE_PASSWORD
echo ""
echo "************************************"
echo " zoo3"
echo "************************************"
echo -e "$ZK_CMD1" | openssl 2>&1 s_client -quiet -connect $ZOO3_URL -CAfile $KEYSTORE_DIR/intermediate.crt -cert $KEYSTORE_DIR/client.${DOMAIN}_cert.pem -key $KEYSTORE_DIR/client.${DOMAIN}_key.pem -pass pass:$KEYSTORE_PASSWORD
echo -e "$ZK_CMD2" | openssl 2>&1 s_client -quiet -connect $ZOO3_URL -CAfile $KEYSTORE_DIR/intermediate.crt -cert $KEYSTORE_DIR/client.${DOMAIN}_cert.pem -key $KEYSTORE_DIR/client.${DOMAIN}_key.pem -pass pass:$KEYSTORE_PASSWORD