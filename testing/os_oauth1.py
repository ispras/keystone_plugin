from keystone_plugin.testing.base import TestKeystoneBase
import requests

class TestKeystoneOSOAuth1(TestKeystoneBase):
    #requires domain, role and user be created in given order

    def setUp(self):
        super(TestKeystoneOSOAuth1, self).setUp()
        self.url = self.host + '/v3/OS-OAUTH1/'
        self.admin_auth()

    def request_token(self):
        self.headers['Requested-Project-Id'] = ''
        self.headers['Authorization'] = "OAuth realm=\"http://sp.example.com/\", oauth_consumer_key=\"0685bd9184jfhq22\", oauth_token=\"ad180jjd733klru7\", oauth_signature_method=\"HMAC-SHA1\",  oauth_signature=\"wOJIO9A2W5mFwDgiDvZbTSMK%2FPY%3D\", oauth_timestamp=\"137131200\", oauth_nonce=\"4572616e48616d6d65724c61686176\", oauth_version=\"1.0\""
        self.res = requests.post(self.url + 'request_token', headers = self.headers)
        self.checkCode(201)