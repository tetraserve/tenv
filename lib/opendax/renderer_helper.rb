module Opendax

  # TODO: move to Gcp

  class RendererHelper

    def self.cloudflare_internal(resource, dnsname, hostname)
      return <<"EOS"
resource "cloudflare_record" "#{resource}" {
  zone_id = var.cloudflare_zone_id
  name    = "#{dnsname}"
  value   = google_compute_instance.#{hostname}.network_interface[0].network_ip
  type    = "A"
  ttl     = 1
}
EOS
    end

    def self.cloudflare_external(resource, dnsname, hostname)
      return <<"EOS"
resource "cloudflare_record" "#{resource}" {
  zone_id = var.cloudflare_zone_id
  name    = "#{dnsname}"
  value   = google_compute_address.#{hostname}.address
  type    = "A"
  ttl     = 1
}
EOS
    end

  end

end
