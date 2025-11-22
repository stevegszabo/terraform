output "google_privateca_certificate_authority_csr" {
  value = data.google_privateca_certificate_authority.this.pem_csr
}
