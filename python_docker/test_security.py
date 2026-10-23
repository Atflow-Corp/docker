"""Run inside a built image: python /tests/test_security.py."""

import hashlib
import ssl
import unittest
from importlib.metadata import version
from pathlib import Path

from pip._vendor import certifi
from pip._vendor.packaging.version import Version

# https://emudhra.we-have-a-problem.com/roots.json
DISTRUSTED_ROOTS = {
    "7dd78d5f4f13459a83dff9abbba62edbaf6f2d102bf257fd712f4d9f2746ed8d",
    "f2edaaff3d9b701fb4d14c9f285f8c0bad90fc3bcc1fa07d47f4718edaba34a5",
    "d7a7a0fb5d7e2731d771e9484ebcdef71d5f0c3e0a2948782bc83ee0ea699ef4",
    "86a1ecba089c4a8d3bbe2734c612ba341d813e043cf9e8a862cd5c57a36bbe6b",
}


class ImageSecurityTests(unittest.TestCase):
    def test_global_pip_is_patched(self):
        self.assertGreaterEqual(Version(version("pip")), Version("26.2.2"))

    def test_trust_stores_exclude_compromised_roots(self):
        paths = {Path("/etc/ssl/certs/ca-certificates.crt"), Path(certifi.where())}
        paths.update(Path("/etc/ssl/certs").glob("*.pem"))
        paths.update(Path("/usr/lib/python3/dist-packages").rglob("cacert.pem"))
        for path in sorted(paths):
            with self.subTest(bundle=str(path)):
                context = ssl.SSLContext(ssl.PROTOCOL_TLS_CLIENT)
                context.load_verify_locations(cafile=str(path))
                fingerprints = {
                    hashlib.sha256(cert).hexdigest() for cert in context.get_ca_certs(binary_form=True)
                }
                self.assertFalse(fingerprints & DISTRUSTED_ROOTS)


if __name__ == "__main__":
    unittest.main()
