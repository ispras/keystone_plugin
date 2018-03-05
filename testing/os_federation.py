from keystone_plugin.testing.base import TestKeystoneBase
import requests
from pprint import pprint
import json

class TestKeystoneOSFederation(TestKeystoneBase):
    #requires domain, role and user be created in given order

    def setUp(self):
        super(TestKeystoneOSFederation, self).setUp()
        self.url = self.host + '/v3/OS-FEDERATION/'
        self.admin_auth()

    def get_token(self):
        json_file = 'keystone_plugin/testing/rules_0.json'
        body = {
            "mapping": json.load(open(json_file))
        }
        self.res = requests.patch(self.url + 'mappings/' + 'test_map', headers = self.headers, json = body)
        self.checkCode(200)
        self.res = requests.get(self.url + 'identity_providers/' + 'test_provider' + '/protocols' + '/test_protocol' + '/auth', headers = self.headers)
        self.checkCode(200)

    def access_token(self):
        params = {
            'code' : '4/AAB4QLXuX7BaEudzXsJEYWUVag5Yvkne5gnDgfLoGMkO2uzQjz5mgJq4FvqRwlgMUduATkJbQbEA4iBkGUSR1t0',
            'redirect_uri' : "http://localhost:8001/v3/OS-OAUTH2/callback",
            'client_id' : '649174633040-h5urg19giljnv4262ihsbh75a4hjtfrj.apps.googleusercontent.com',
            'client_secret' : 'LMUHFLQJSRF2YB4zU8cRJTdY',
            'grant_type' : 'authorization_code'
        }
        self.res = requests.post("https://www.googleapis.com/oauth2/v4/token", json = params)
        self.checkCode(200)

    def identity_provider(self):
        # self.res = requests.delete(self.host + '/v3/domains/' + self.domain_id, headers = self.headers)
        # self.checkCode(204)

        query = {
            'name' : 'Domain for Identity Provider test_provider'
        }
        self.res = requests.get(self.host + '/v3/domains', params = query, headers = self.headers)
        self.checkCode(200)

        body = {
            'identity_provider' : {}
        }
        if self.res.json()['domains']:
            self.domain_id = self.res.json()['domains'][0]['id']
            body['identity_provider']['domain_id'] = self.domain_id

        self.res = requests.put(self.url + 'identity_providers/' + 'test_provider', headers = self.headers, json = body)
        self.checkCode(201)
        self.res = requests.get(self.url + 'identity_providers/', headers = self.headers)
        self.checkCode(200)
        self.res = requests.get(self.url + 'identity_providers/' + 'test_provider', headers = self.headers)
        self.checkCode(200)
        body = {
            'identity_provider' : {
                'remote_ids' : ['a', 'b', 'b']
            }
        }
        self.res = requests.patch(self.url + 'identity_providers/' + 'test_provider', headers = self.headers, json = body)
        self.checkCode(200)
        self.res = requests.delete(self.url + 'identity_providers/' + 'test_provider', headers = self.headers)
        self.checkCode(204)

    def mapping(self):
        json_file = 'keystone_plugin/testing/rules_0.json'
        body = {
            "mapping": json.load(open(json_file))
        }
        self.res = requests.put(self.url + 'mappings/test_map', headers = self.headers, json = body)
        self.checkCode(201)
        self.res = requests.get(self.url + 'mappings', headers = self.headers)
        self.checkCode(200)
        self.res = requests.get(self.url + 'mappings/' + 'test_map', headers = self.headers)
        self.checkCode(200)
        # self.res = requests.patch(self.url + 'mappings/' + 'test_map', headers = self.headers, json = body)
        # self.checkCode(200)
        # self.res = requests.delete(self.url + 'mappings/' + 'test_map', headers = self.headers)
        # self.checkCode(204)

    def protocols(self):
        body = {
            'protocol' : {
                'mapping_id' : 'test_map'
            }
        }
        self.res = requests.put(self.url + 'identity_providers/' + 'test_provider' + '/protocols' + '/test_protocol', headers = self.headers, json = body)
        self.checkCode(201)
        self.res = requests.get(self.url + 'identity_providers/' + 'test_provider' + '/protocols', headers = self.headers)
        self.checkCode(200)
        self.res = requests.get(self.url + 'identity_providers/' + 'test_provider' + '/protocols' + '/test_protocol', headers = self.headers)
        self.checkCode(200)
        self.res = requests.patch(self.url + 'identity_providers/' + 'test_provider' + '/protocols' + '/test_protocol', headers = self.headers, json = body)
        self.checkCode(200)
        self.res = requests.delete(self.url + 'identity_providers/' + 'test_provider' + '/protocols' + '/test_protocol', headers = self.headers)
        self.checkCode(204)

    def service_providers(self):
        body = {
            'service_provider' : {
                "auth_url": "https://example.com/identity/v3/OS-FEDERATION/identity_providers/acme/protocols/saml2/auth",
                "description": "Remote Service Provider",
                "enabled": True,
                "sp_url": "https://example.com/identity/Shibboleth.sso/SAML2/ECP"
            }
        }
        self.res = requests.put(self.url + 'service_providers/' + 'test_provider', headers = self.headers, json = body)
        self.checkCode(201)
        self.res = requests.get(self.url + 'service_providers/', headers = self.headers)
        self.checkCode(200)
        self.res = requests.get(self.url + 'service_providers/' + 'test_provider', headers = self.headers)
        self.checkCode(200)
        self.res = requests.patch(self.url + 'service_providers/' + 'test_provider', headers = self.headers, json = body)
        self.checkCode(200)
        self.res = requests.delete(self.url + 'service_providers/' + 'test_provider', headers = self.headers)
        self.checkCode(204)

    def init(self):
        # Create federated domain
        body = {
            "domain": {
                "name": "Federated",
                "description": "domain for federated users",
                "enabled":  True
            }
        }
        self.res = requests.post(self.host + '/v3/domains', json = body, headers = self.headers)
        self.checkCode(201)
        self.domain_id = self.res.json()['domain']['id']

        # Create federated project
        body = {
            "project": {
                "name": "Federated",
                "description": "project for federated users",
                'domain_id' : self.domain_id,
                "enabled":  True
            }
        }
        self.res = requests.post(self.host + '/v3/projects', json = body, headers = self.headers)
        self.checkCode(201)
        self.project_id = self.res.json()['project']['id']

        # Create federated group
        body = {
            'group' : {
                'description' : 'group for federated users',
                'domain_id' : self.domain_id,
                'name' : 'federated'
            }
        }
        self.res = requests.post(self.host + '/v3/groups', json = body, headers = self.headers)
        self.checkCode(201)

        # Get role member
        self.group_id = self.res.json()['group']['id']
        query = {
            'name' : 'member'
        }
        self.res = requests.get(self.host + '/v3/roles', params = query, headers = self.headers)
        self.checkCode(200)
        self.role_id = self.res.json()['roles'][0]['id']

        #Assign role
        self.res = requests.put(self.host + '/v3/domains/' + self.domain_id + '/groups/' + self.group_id + '/roles/' + self.role_id,
                                json={}, headers = self.headers)  # json object is required
        self.checkCode(204)
        self.res = requests.put(self.host + '/v3/projects/' + self.project_id + '/groups/' + self.group_id + '/roles/' + self.role_id,
                                json={}, headers = self.headers)  # json object is required
        self.checkCode(204)

    def get_scopes (self):
        self.res = requests.get(self.url + 'projects', headers = self.headers)
        self.checkCode(200)
        pprint(self.res.json())
        self.res = requests.get(self.url + 'domains', headers = self.headers)
        self.checkCode(200)