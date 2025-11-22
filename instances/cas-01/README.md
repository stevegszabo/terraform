# csr

```
cat > subordinate.csr <<EOF
data.google_privateca_certificate_authority.this.pem_csr
EOF

cat > root.conf <<EOF
[req]
distinguished_name = req_distinguished_name
x509_extensions    = v3_ca
prompt             = no
[req_distinguished_name]
commonName = domain.ca
[v3_ca]
subjectKeyIdentifier=hash
basicConstraints=critical, CA:true
EOF

cat > extensions.conf <<EOF
basicConstraints=critical,CA:TRUE,pathlen:1
keyUsage=critical,keyCertSign,cRLSign
extendedKeyUsage=critical,serverAuth,clientAuth
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid
subjectAltName=DNS:istiod.istio-system.svc
EOF

openssl req -x509 -new -nodes -config root.conf -keyout rootCA.key -days 3000 -out rootCA.crt -batch
openssl x509 -req -in subordinate.csr -CA rootCA.crt -CAkey rootCA.key -CAcreateserial -out subordinate.crt -days 1095 -sha256 -extfile extensions.conf

cp rootCA.crt      $HOME/src/terraform/instances/cas-01/
cp subordinate.crt $HOME/src/terraform/instances/cas-01/
```

# istio-system namespace

```
kc create ns istio-system
kc -n istio-system create cm asm-options
kc -n istio-system patch  cm asm-options --type merge -p '{"data": {"ASM_OPTS": "CA=PRIVATECA;CAAddr=projects/project-01-xxxxxx/locations/northamerica-northeast2/caPools/cas-alpha"}}'
kc -n istio-system get    cm asm-options -o json | jq -r .data.ASM_OPTS
```
