#https://gist.github.com/0sc/2e2bdb19bcc0051e715625075e7cc068
#enc = encrypt_string('string-to-encrypt') #=> "8F22010F2ABEC116345274374C444F502530D37ABA018CA7F49EC6CA1053FBD7"
#dec = decrypt_string(enc) #=> "string-to-encrypt"

require 'openssl'

module Dockerconf
  class SimpleCipher
    def self.encrypt_string(str)
      cipher_salt1 = 'some-random-salt-'
      cipher_salt2 = 'another-random-salt-'
      cipher = OpenSSL::Cipher.new('AES-128-ECB').encrypt
      cipher.key = OpenSSL::PKCS5.pbkdf2_hmac_sha1(cipher_salt1, cipher_salt2, 20_000, cipher.key_len)
      encrypted = cipher.update(str) + cipher.final
      encrypted.unpack('H*')[0].upcase
    end
    def self.decrypt_string(encrypted_str)
      cipher_salt1 = 'some-random-salt-'
      cipher_salt2 = 'another-random-salt-'
      cipher = OpenSSL::Cipher.new('AES-128-ECB').decrypt
      cipher.key = OpenSSL::PKCS5.pbkdf2_hmac_sha1(cipher_salt1, cipher_salt2, 20_000, cipher.key_len)
      decrypted = [encrypted_str].pack('H*').unpack('C*').pack('c*')
      cipher.update(decrypted) + cipher.final
    end
  end
end