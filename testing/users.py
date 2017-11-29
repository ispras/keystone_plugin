from keystone_plugin.testing.base import TestKeystoneBase
import requests

class TestKeystoneUsers(TestKeystoneBase):
    def setUp(self):
        super(TestKeystoneUsers, self).setUp()
        self.host = self.host + '/v3/users/'

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

    def delete(self):
        user_id = 'bfeef63f-ff7e-446b-95a5-66b8a2c06710'
        self.res = requests.delete(self.host + user_id)
        self.checkCode(204)

    def get_info(self):
        user_id = '6232b7f1-b6fd-418e-9a19-14b115164981'
        self.res = requests.get(self.host + user_id)
        self.checkCode(200)

    def update(self):
        user_id = '6232b7f1-b6fd-418e-9a19-14b115164981'
        body = {
            "user" : {
                'enabled': True,
                'name' : 'check',
                'password' : 'secret2'
            }
        }
        self.res = requests.patch(self.host + user_id, json = body)
        self.checkCode(200)

    def list_groups(self):
        user_id = '51672d4d-4cd0-417c-88f4-37f3364f2c7a'
        self.res = requests.get(self.host + user_id + '/groups')
        self.checkCode(200)

    def list_projects(self):
        user_id = '51672d4d-4cd0-417c-88f4-37f3364f2c7a'
        self.res = requests.get(self.host + user_id + '/projects')
        self.checkCode(200)

    def change_password(self):
        user_id = '51672d4d-4cd0-417c-88f4-37f3364f2c7a'
        body = {
            'user' : {
                'password' : 'new_tester',
                'original_password' : 'tester'
            }
        }
        self.res = requests.post(self.host + '/password', json = body)
        self.checkCode(204)
