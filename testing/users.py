from base import TestKeystoneBase
import requests
from pprint import pprint

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
            # 'password_expires_at': 'password_expires_at',
            # 'protocol_id': 'protocol_id',
            # 'unique_id': 'unique_id'
        }
        res = requests.get(self.host, params = query)
        self.checkCode(res, 200)

        pprint(res.json())

    def create_local(self):
        body = {
            "user": {
                "enabled": "true",
                "name": "admin",
                "password": "myadminpass",
                "domain_id": "db680c6e-d4e1-4a59-af41-8b30ea8dce6d",
            }
        }
        res = requests.post(self.host, json = body)
        self.checkCode(res, 201)

        response = res.json()
        for k, v in response.items():
            if k != 'user':
                print(k, '\n\t', v)
            else:
                print(k)
                for uk, uv in v.items():
                    print('\t', uk, '\t:\t', uv)
        self.assertTrue(bool(response['user']['enabled']))

        self.user_id = response['user']['id']

    def create_nonlocal(self):
        body = {
            "user": {
                "name": "nonloc_user"
            }
        }
        res = requests.post(self.host, json = body)
        self.checkCode(res, 201)

        response = res.json()
        for k, v in response.items():
            if k != 'user':
                print(k, '\n\t', v)
            else:
                print(k)
                for uk, uv in v.items():
                    print('\t', uk, '\t:\t', uv)
        self.assertTrue(bool(response['user']['enabled']))

        self.user_id = response['user']['id']

    def delete(self):
        user_id = 'bfeef63f-ff7e-446b-95a5-66b8a2c06710'
        res = requests.delete(self.host + user_id)
        self.checkCode(res, 204)

    def get_info(self):
        user_id = '6232b7f1-b6fd-418e-9a19-14b115164981'
        res = requests.get(self.host + user_id)
        self.checkCode(res, 200)

        response = res.json()
        for k, v in response.items():
            if k != 'user':
                print(k, '\n\t', v)
            else:
                print(k)
                for uk, uv in v.items():
                    print('\t', uk, '\t:\t', uv)

    def update(self):
        user_id = '6232b7f1-b6fd-418e-9a19-14b115164981'
        body = {
            "user" : {
                'enabled': True,
                'name' : 'check',
                'password' : 'secret2'
            }
        }
        res = requests.patch(self.host + user_id, json = body)
        self.checkCode(res, 200)

        response = res.json()
        for k, v in response.items():
            if k != 'user':
                print(k, '\n\t', v)
            else:
                print(k)
                for uk, uv in v.items():
                    print('\t', uk, '\t:\t', uv)

    def list_groups(self):
        user_id = '51672d4d-4cd0-417c-88f4-37f3364f2c7a'
        res = requests.get(self.host + user_id + '/groups')
        self.checkCode(res, 200)

        response = res.json()
        for k, v in response.items():
            if k != 'groups':
                print(k, '\n\t', v)
            else:
                print(k)
                for uk, uv in v.items():
                    print('\t', uk, '\t:\t', uv)

    def list_projects(self):
        user_id = '51672d4d-4cd0-417c-88f4-37f3364f2c7a'
        res = requests.get(self.host + user_id + '/projects')
        self.checkCode(res, 200)

        response = res.json()
        for k, v in response.items():
            if k != 'projects':
                print(k, '\n\t', v)
            else:
                print(k)
                for uk, uv in v.items():
                    print('\t', uk, '\t:\t', uv)

    def change_password(self):
        user_id = '51672d4d-4cd0-417c-88f4-37f3364f2c7a'
        body = {
            'user' : {
                'password' : 'new_tester',
                'original_password' : 'tester'
            }
        }
        res = requests.post(self.host + '/password', json = body)
        self.checkCode(res, 204)
