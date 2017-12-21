from keystone_plugin.testing.base import TestKeystoneBase
import requests

class TestKeystoneUsers(TestKeystoneBase):
    def setUp(self):
        super(TestKeystoneUsers, self).setUp()
        self.url = self.host + '/v3/users/'
        self.user_id = '919a95dd-f955-4c72-b517-fd80af3f36a7'
        self.domain_id = '7bba3639-1d1e-4999-9b14-d8392b6a025d'
        self.project_id = '899f724c-80ad-456a-a584-040d3748a5b8'
        self.auth()
        self.headers = {
            'X-Auth-Token': self.auth_token
        }


    def list(self):
        query = {
            # 'domain_id' : 'domain_id',
            'enabled': 'true',
            # 'idp_id': 'idp_id',
            # 'name': 'name',
            # 'password_expires_at': 'lte:2017-12-08T13:00:00Z',
            # 'protocol_id': 'protocol_id',
            # 'unique_id': 'unique_id'
        }
        self.res = requests.get(self.url, params = query, headers = self.headers)
        self.checkCode(200)

    def create_local(self):
        body = {
            "user": {
                "enabled": "true",
                "name": "test_default_project",
                "password": "myadminpass",
                'default_project_id': self.project_id
                # "domain_id": self.domain_id,
            }
        }
        self.res = requests.post(self.url, json = body, headers = self.headers)
        self.checkCode(201)
        self.user_id = self.res.json()['user']['id']

    def create_nonlocal(self):
        body = {
            "user": {
                "name": "nonloc_user"
            }
        }
        self.res = requests.post(self.url, json = body, headers = self.headers)
        self.checkCode(201)
        self.user_id = self.res.json()['user']['id']

    def delete(self):
        self.res = requests.delete(self.url + self.user_id, headers = self.headers)
        self.checkCode(204)

    def get_info(self):
        self.res = requests.get(self.url + self.user_id, headers = self.headers)
        self.checkCode(200)

    def update(self):
        # self.create_nonlocal()
        body = {
            "user" : {
                'enabled': True,
                'name' : 'local_user',
                'password' : 'secret2'
            }
        }
        self.res = requests.patch(self.url + self.user_id, json = body, headers = self.headers)
        self.checkCode(200)

    def list_groups(self):
        self.res = requests.get(self.url + self.user_id + '/groups', headers = self.headers)
        self.checkCode(200)

    def list_projects(self):
        self.res = requests.get(self.url + self.user_id + '/projects', headers = self.headers)
        self.checkCode(200)

    def change_password(self):
        body = {
            'user' : {
                'password' : 'myadminpassword',
                'original_password' : 'myadminpassword'
            }
        }
        self.res = requests.post(self.url + self.user_id + '/password', json = body, headers=self.headers)
        self.checkCode(204)
