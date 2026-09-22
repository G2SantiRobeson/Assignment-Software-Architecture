require "openssl"
require "fileutils"

host = ENV.fetch("APP_HOST", "app.localhost")
raise "APP_HOST must be a DNS hostname" unless host.match?(/\A[a-zA-Z0-9][a-zA-Z0-9.-]*\z/)

root = ARGV.fetch(0)
FileUtils.mkdir_p(root)
key = OpenSSL::PKey::RSA.new(2048)
cert = OpenSSL::X509::Certificate.new
cert.version = 2
cert.serial = Random.rand(1..2**128)
cert.subject = OpenSSL::X509::Name.parse("/CN=#{host}")
cert.issuer = cert.subject
cert.public_key = key.public_key
cert.not_before = Time.now - 60
cert.not_after = Time.now + 365 * 86_400
factory = OpenSSL::X509::ExtensionFactory.new
factory.subject_certificate = cert
factory.issuer_certificate = cert
cert.add_extension(factory.create_extension("basicConstraints", "CA:TRUE", true))
cert.add_extension(factory.create_extension("keyUsage", "digitalSignature,keyEncipherment,keyCertSign", true))
cert.add_extension(factory.create_extension("extendedKeyUsage", "serverAuth"))
cert.add_extension(factory.create_extension("subjectAltName", "DNS:#{host},DNS:localhost,IP:127.0.0.1"))
cert.sign(key, OpenSSL::Digest.new("SHA256"))
File.write(File.join(root, "tls.key"), key.to_pem, perm: 0o600)
File.write(File.join(root, "tls.crt"), cert.to_pem)
puts "Generated local certificate for #{host}"
