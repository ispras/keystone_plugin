from keystone_plugin.testing.base import TestKeystoneBase
import requests

class TestKeystoneUsers(TestKeystoneBase):
    def setUp(self):
        super(TestKeystoneUsers, self).setUp()
        self.host = self.host + '/v3/users/'
        self.user_id = "fa0435c0-884b-46f5-a5e8-ea45cd5fc8c1"

    def list(self):
        query = {
            # 'domain_id' : 'domain_id',
            'enabled': 'true',
            # 'idp_id': 'idp_id',
            # 'name': 'name',
            # 'password_expiself.res_at': 'password_expiself.res_at',
            # 'protocol_id': 'protocol_id',
            # 'unique_id': 'unique_id'
        }
        self.res = requests.get(self.host, params = query)
        self.checkCode(200)

    def create_local(self):
        body = {
            "user": {
                "enabled": "true",
                "name": "admin",
                "password": "myadminpass",
                "domain_id": "ffb8809c-e262-4703-b1ba-8af5c9f8a134",
            }
        }
        self.res = requests.post(self.host, json = body)
        self.checkCode(201)

    def create_nonlocal(self):
        body = {
            "user": {
                "name": "nonloc_user"
            }
        }
        self.res = requests.post(self.host, json = body)
        self.checkCode(201)
        self.user_id = self.res.json()['user']['id']

    def delete(self):
        self.res = requests.delete(self.host + self.user_id)
        self.checkCode(204)

    def get_info(self):
        self.res = requests.get(self.host + self.user_id)
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
        self.res = requests.patch(self.host + self.user_id, json = body)
        self.checkCode(200)

    def list_groups(self):
        self.res = requests.get(self.host + self.user_id + '/groups')
        self.checkCode(200)

    def list_projects(self):
        self.res = requests.get(self.host + self.user_id + '/projects')
        self.checkCode(200)

    def change_password(self):
        body = {
            'user' : {
                'password' : 'new_tester',
                'original_password' : 'tester'
            }
        }
        self.res = requests.post(self.host + '/password', json = body)
        self.checkCode(204)
