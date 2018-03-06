from keystone_plugin.testing.base import TestKeystoneBase
import requests

class TestKeystoneOSOAuth2(TestKeystoneBase):
    #requires domain, role and user be created in given order

    def setUp(self):
        super(TestKeystoneOSOAuth2, self).setUp()
        self.url = self.host + '/v3/OS-OAUTH2/'
        self.admin_auth()
        self.consumer_key = '649174633040-h5urg19giljnv4262ihsbh75a4hjtfrj.apps.googleusercontent.com'
        self.user_id = '1669171946496195'

    def request_token(self):
        params = {"authuser":"0","state":"106b6801-5e29-4059-b4e6-8c38ee3ee4d8","code":"4\/AACaTS7PXPpahFgzeFczRHOYVCKfceE4uIEZzhtiBbaQ4zPLWRCdF47fQtQgq447MMK5JxftSl2vHRGaztGLM98","prompt":"consent","hd":"phystech.edu","session_state":"dee4004400508b403eec14ea2fd00c7e66044d84..78ac"}
        # self.headers['Requested-Project-Id'] = '533e9371-5070-435b-9aa6-9715b1d6003c'
        # self.headers['Authorization'] = "OAuth realm=\"http://sp.example.com/\", oauth_consumer_key=\"0685bd9184jfhq22\", oauth_token=\"ad180jjd733klru7\", oauth_signature_method=\"HMAC-SHA1\",  oauth_signature=\"wOJIO9A2W5mFwDgiDvZbTSMK%2FPY%3D\", oauth_timestamp=\"137131200\", oauth_nonce=\"4572616e48616d6d65724c61686176\", oauth_version=\"1.0\""
        self.res = requests.get(self.url + 'auth/callback/' + self.consumer_key, json = params)
        self.checkCode(200)

    def create_consumers(self):
        body = {
            'consumer': {
                'id': '649174633040-h5urg19giljnv4262ihsbh75a4hjtfrj.apps.googleusercontent.com',
                'secret': 'LMUHFLQJSRF2YB4zU8cRJTdY',
                'description': 'Google request https://accounts.google.com/.well-known/openid-configuration',
                'auth_url': 'https://accounts.google.com/o/oauth2/v2/auth',
                'token_url': 'https://www.googleapis.com/oauth2/v4/token',
                'userinfo_url': 'https://www.googleapis.com/oauth2/v1/userinfo'
            }
        }
        self.res = requests.post(self.url + 'consumers', headers=self.headers, json=body)
        self.checkCode(201)

        body = {
            'consumer' : {
                'id' : '212814432631056',
                'secret' : 'd0403148bbff748b06be87d3121a316b',
                'description' : 'Facebook OAuth2',
                'auth_url' : 'https://www.facebook.com/v2.12/dialog/oauth',
                'token_url' : 'https://graph.facebook.com/v2.12/oauth/access_token',
                'userinfo_url' : 'https://graph.facebook.com/me?fields=id,email'
            }
        }
        self.res = requests.post(self.url + 'consumers', headers = self.headers, json = body)
        self.checkCode(201)

    def list(self):
        self.res = requests.get(self.url + 'consumers', headers = self.headers)
        self.checkCode(200)

    def access_tokens(self):
        self.res = requests.get(self.host + '/v3/users/'+ self.user_id + '/OS-OAUTH2/access_tokens', headers = self.headers)
        self.checkCode(200)
        self.access_token_id = self.res.json()['access_tokens'][0]['id']
        self.res = requests.get(self.host + '/v3/users/'+ self.user_id + '/OS-OAUTH2/access_tokens/' + self.access_token_id, headers = self.headers)
        self.checkCode(200)
        self.res = requests.delete(self.host + '/v3/users/'+ self.user_id + '/OS-OAUTH2/access_tokens/' + self.access_token_id, headers = self.headers)
        self.checkCode(204)
        self.res = requests.get(self.host + '/v3/users/'+ self.user_id + '/OS-OAUTH2/access_tokens/' + self.access_token_id, headers = self.headers)
        self.checkCode(404)
