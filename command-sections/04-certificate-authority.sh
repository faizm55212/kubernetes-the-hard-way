certs=(
  "admin" "worker-0" "worker-1"
  "kube-proxy" "kube-scheduler"
  "kube-controller-manager"
  "kube-api-server"
  "service-accounts"
)

for i in ${certs[*]}; do
  mkdir -p $i
  openssl genrsa -out "${i}/${i}.key" 4096

  openssl req -new -key "${i}/${i}.key" -sha256 \
    -config "ca.conf" -section ${i} \
    -out "${i}/${i}.csr"

  openssl x509 -req -days 3653 -in "${i}/${i}.csr" \
    -copy_extensions copyall \
    -sha256 -CA "ca.crt" \
    -CAkey "ca.key" \
    -CAcreateserial \
    -out "${i}/${i}.crt"
done