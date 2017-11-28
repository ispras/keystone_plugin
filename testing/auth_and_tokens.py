from base import TestKeystoneBase
import requests

class TestKeystoneAuthAndTokens(TestKeystoneBase):
    def setUp(self):
        super(TestKeystoneAuthAndTokens, self).setUp()
        self.host = self.host + '/v3/auth/'
    def password_unscoped(self):
        body = {
            'auth' : {
                'identity' : {
                    'methods' : [ 'password' ],
                    'password' : {
                        'user' : {
                            'name' : 'admin',
                            'domain' : {
                                'name' : 'default_domain'
                            },
                            'password' : 'myadminpass'
                        }
                    }
                }
            }
        }
        self.res = requests.post(self.host + 'tokens', json = body)
        self.checkCode(201)

    def get_catalog(self):
        token_id = ''
        headers = {
            "X-Auth_token" : token_id
        }
        self.res = requests.get(self.host + 'catalog')
        self.checkCode(200)
