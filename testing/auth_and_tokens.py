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
                            'password' : 'new_tester'
                        }
                    }
                }
            }
        }
        res = requests.post(self.host + 'tokens', json = body)
        self.checkCode(res, 201)

        response = res.json()
        for k, v in response['token'].items():
            print(k, '\n\t', v)

    def get_catalog(self):
        token_id = ''
        headers = {
            "X-Auth_token" : token_id
        }
        res = requests.get(self.host + 'catalog')
        self.checkCode(res, 200)

        response = res.json()
        for k, v in response['token'].items():
            print(k, '\n\t', v)