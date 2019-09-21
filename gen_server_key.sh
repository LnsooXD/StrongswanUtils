#!/bin/sh

# Generate CA certificate and server certificate for Strongswan server.
# Author: LnsooXD<LnsooXD@gmail.com>

SS_CA_PRIVATE_KEY_PATH="private/strongswan-ca-private-key.pem"
SS_CA_CERT_PATH="cacerts/strongswan-ca-cert.pem"

SS_SERVER_PRIVATE_KEY_PATH="private/strongswan-server-private-key.pem"
SS_SERVER_CERT_PATH="certs/strongswan-server-cert.pem"

KEY_SIZE_DEFAULT=4096
KEY_LIFETIME_DEFAULT=3650

DN_DEFAULT_C=CN
DN_DEFAULT_O=Lnsoo
DN_DEFAULT_CA_CN="Lnsoo org"
DN_DEFAULT_CN=0.0.0.0

read -p "Key size[${KEY_SIZE_DEFAULT}]:" KEY_SIZE
read -p "Key lifetime (Days)[${KEY_LIFETIME_DEFAULT}]:" KEY_LIFETIME
read -p "Country[${DN_DEFAULT_C}]:" DN_C
read -p "Organization[${DN_DEFAULT_O}]:" DN_O
read -p "CA common name[${DN_DEFAULT_CA_CN}]:" DN_CA_CN
read -p "IP Or Domain[${DN_DEFAULT_CN}]:" DN_CN

KEY_SIZE=${KEY_SIZE:-${KEY_SIZE_DEFAULT}}
KEY_LIFETIME=${KEY_LIFETIME:-${KEY_LIFETIME_DEFAULT}}
DN_C=${DN_C:-${DN_DEFAULT_C}}
DN_O=${DN_O:-${DN_DEFAULT_O}}
DN_CA_CN=${DN_CA_CN:-${DN_DEFAULT_CA_CN}}
DN_CN=${DN_CN:-${DN_DEFAULT_CN}}

echo 
echo
echo "=========================== Information ==========================="
echo "Key size: ${KEY_SIZE}"
echo "Key lifetime: ${KEY_LIFETIME} (Days)"
echo "Country: ${DN_C}"
echo "Organization: ${DN_O}"
echo "CA common name: ${DN_CA_CN}"
echo "IP Or Domain: ${DN_CN}"
echo "==================================================================="

echo 
echo
echo "Generating CA certificate ..."

mkdir -p private && \
mkdir -p cacerts && \
mkdir -p certs \

# Generate a private key for CA certificate.
strongswan pki \
    --gen \
    --type rsa \
    --size ${KEY_SIZE} \
    --outform pem \
    > "${SS_CA_PRIVATE_KEY_PATH}" \

# Generate a self-signed CA certificate with the CA private key.
strongswan pki \
    --self \
    --ca \
    --lifetime ${KEY_LIFETIME} \
    --in "${SS_CA_PRIVATE_KEY_PATH}" \
    --type rsa \
    --dn "C=${DN_C}, O=${DN_O}, CN=${DN_CA_CN}" \
    --outform pem \
    > "${SS_CA_CERT_PATH}" \

echo "CA certificate at ${SS_CA_CERT_PATH}:"
strongswan pki \
    --print \
    --in "${SS_CA_CERT_PATH}" \

echo 
echo
sleep 1
echo "Generating server keys ..."
echo 
echo

# Generate a private key for server certificate.
strongswan pki \
    --gen \
    --type rsa \
    --size ${KEY_SIZE} \
    --outform pem \
    > "${SS_SERVER_PRIVATE_KEY_PATH}" \

# Create a server certificate with the server private key signed by the CA certificate.
strongswan pki \
    --pub \
    --type rsa \
    --in "${SS_SERVER_PRIVATE_KEY_PATH}" \
    --outform pem \
    | \
strongswan pki \
    --issue \
    --lifetime ${KEY_LIFETIME_DEFAULT} \
    --cakey "${SS_CA_PRIVATE_KEY_PATH}" \
    --cacert "${SS_CA_CERT_PATH}" \
    --dn "C=${DN_C}, O=${DN_O}, CN=${DN_CN}" \
    --san "${DN_CN}" \
    --flag serverAuth \
    --flag ikeIntermediate \
    --outform pem \
    > "${SS_SERVER_CERT_PATH}" \

echo "VPN server cert at ${SS_SERVER_CERT_PATH}:"
strongswan pki \
    --print \
    --in "${SS_SERVER_CERT_PATH}"
