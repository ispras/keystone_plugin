from keystone_plugin.testing.base import TestKeystoneBase
import requests

class TestKeystoneOSRevoke(TestKeystoneBase):
    #requires domain, role and user be created in given order

    def setUp(self):
        super(TestKeystoneOSRevoke, self).setUp()
        self.url = self.host + '/v3/OS-REVOKE/'
        self.admin_auth()

    def check(self):
        query = {
            'since' : 0
        }
        self.res = requests.get(self.url + 'events', headers = self.headers, params = query)
        self.checkCode(200)