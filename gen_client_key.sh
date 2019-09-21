#!/bin/sh

# Generate client certificate for Strongswan client.
# Author: LnsooXD<LnsooXD@gmail.com>

SS_CA_PRIVATE_KEY_PATH="private/strongswan-ca.key.pem"
SS_CA_CERT_PATH="cacerts/strongswan-ca.cert.pem"

# Parse organization from CA certificate.
SS_CA_O=`strongswan pki \
	--print \
	--in "${SS_CA_CERT_PATH}" \
	| \
	awk -F '"' '/subject:/{ret = index($2, "C=");ret=substr($2,ret);split(ret,arr,",");split(arr[1],arr,"=");print arr[2]}'
`
# Parse CA common name from CA certificate.
SS_CA_CN=`strongswan pki \
	--print \
	--in "${SS_CA_CERT_PATH}" \
	| \
	awk -F '"' '/subject:/{ret = index($2, "CN=");ret=substr($2,ret);split(ret,arr,",");split(arr[1],arr,"=");print arr[2]}'
`


KEY_SIZE_DEFAULT=4096
KEY_LIFETIME_DEFAULT=3650

DN_DEFAULT_C=CN

CLIENT_DEFAULT_USER_NAME="User"
CLIENT_DEFAULT_USER_EMAIL="user@example.com"

read -p "Key size[${KEY_SIZE_DEFAULT}]:" KEY_SIZE
read -p "Key lifetime (Days)[${KEY_LIFETIME_DEFAULT}]:" KEY_LIFETIME
read -p "Country[${DN_DEFAULT_C}]:" DN_C
read -p "User name[${CLIENT_DEFAULT_USER_NAME}]:" CLIENT_USER_NAME
read -p "User email[${CLIENT_DEFAULT_USER_EMAIL}]:" CLIENT_USER_EMAIL

KEY_SIZE=${KEY_SIZE:-${KEY_SIZE_DEFAULT}}
KEY_LIFETIME=${KEY_LIFETIME:-${KEY_LIFETIME_DEFAULT}}
DN_C=${DN_C:-${DN_DEFAULT_C}}
CLIENT_USER_NAME=${CLIENT_USER_NAME:-${CLIENT_DEFAULT_USER_NAME}}
CLIENT_USER_EMAIL=${CLIENT_USER_EMAIL:-${CLIENT_DEFAULT_USER_EMAIL}}

echo 
echo
echo "=========================== Information ==========================="
echo "Key size: ${KEY_SIZE}"
echo "Key lifetime: ${KEY_LIFETIME} (Days)"
echo "Organization: ${SS_CA_O}"
echo "CA common name: ${SS_CA_CN}"
echo "User name: ${CLIENT_USER_NAME}"
echo "User email: ${CLIENT_USER_EMAIL}"
echo "==================================================================="

echo 
echo
echo "Generating client keys and certificates for ${CLIENT_USER_NAME}..."
echo
echo

mkdir -p private && \
mkdir -p cacerts && \
mkdir -p certs &&\
mkdir -p p12-certs


CLIENT_PRIVATE_KEY_PATH="private/strongswan-client-${CLIENT_USER_NAME}.key.pem"
CLIENT_CERT_PATH="certs/strongswan-client-${CLIENT_USER_NAME}.cert.pem"
CLIENT_CERT_P12_CERT_PATH="p12-certs/strongswan-client-${CLIENT_USER_NAME}.cert.p12"

strongswan pki \
	--gen \
	--type rsa \
	--size ${KEY_SIZE} \
	--outform pem \
	> "${CLIENT_PRIVATE_KEY_PATH}"

strongswan pki \
	--pub \
	--in "${CLIENT_PRIVATE_KEY_PATH}" \
	--type rsa \
	| \
strongswan pki \
	--issue \
	--lifetime ${KEY_LIFETIME} \
	--cakey "${SS_CA_PRIVATE_KEY_PATH}" \
	--cacert "${SS_CA_CERT_PATH}" \
	--dn "C=${DN_C}, O=${SS_CA_O}, CN=${CLIENT_USER_EMAIL}" \
	--san ${CLIENT_USER_EMAIL} \
	--outform pem \
	> "${CLIENT_CERT_PATH}" \

echo "Client certificate for ${CLIENT_USER_NAME}:"
strongswan pki \
	--print \
	--in "${CLIENT_CERT_PATH}"
echo

echo "Enter password to protect p12 cert for ${CLIENT_USER_NAME}"
openssl pkcs12 \
	-export \
	-inkey "${CLIENT_PRIVATE_KEY_PATH}" \
	-in "${CLIENT_CERT_PATH}" \
	-name "${CLIENT_USER_NAME}'s VPN Certificate of ${SS_CA_CN}" \
	-certfile "${SS_CA_CERT_PATH}" \
	-caname "${SS_CA_CN}" \
	-out "${CLIENT_CERT_P12_CERT_PATH}"
