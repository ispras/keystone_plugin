from keystone_plugin.testing.base import TestKeystoneBase
import requests

class TestKeystoneOSSimpleCert(TestKeystoneBase):
    #requires domain, role and user be created in given order

    def setUp(self):
        super(TestKeystoneOSSimpleCert, self).setUp()
        self.url = self.host + '/v3/OS-SIMPLE-CERT/'
        self.admin_auth()

    def check(self):
        self.res = requests.get (self.url + 'ca', headers = self.headers)
        self.checkCode(200)
        self.res = requests.get (self.url + 'certificate', headers = self.headers)
        self.checkCode(200)