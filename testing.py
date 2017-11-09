import requests
import unittest
import json

class TestKeystone(unittest.TestCase):
    host = 'http://localhost:8001'
    def checkCode(self, res, code):
        if res.status_code != code:
            try:
                print("Failed with error:", res.reason)
                response = res.json()
                for k, v in response.items():
                    print(k, '\n\t', v)
            except Exception:
                print("Failed with error:", res.reason)
            self.assertEqual(res.status_code, code)

    def test_list_users(self):
        query = {
            # 'domain_id' : 'domain_id',
            'enabled': 'true',
            # 'idp_id': 'idp_id',
            # 'name': 'name',
            # 'password_expires_at': 'password_expires_at',
            # 'protocol_id': 'protocol_id',
            # 'unique_id': 'unique_id'
        }
        res = requests.get(self.host + '/v3/users', params = query)
        self.checkCode(res, 200)

        response = res.json()
        for k, v in response.items():
            if k != 'users':
                print(k, '\n\t', v)
            else:
                print(k)
                for user in v:
                    for uk, uv in user.items():
                        print('\t', uk, '\t:\t', uv)
                    print()

    def test_create_local_user(self):
        body = {
            "user": {
                "enabled": "true",
                "name": "admin",
                "password": "tester"
            }
        }
        res = requests.post(self.host + '/v3/users', json = body)
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

    def test_create_nonlocal_user(self):
        body = {
            "user": {
                "name": "nonloc_user"
            }
        }
        res = requests.post(self.host + '/v3/users', json = body)
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

    def test_create_domain(self):
        body = {
            "domain" : {
                "name": "check_domain",
                "description" : "kuku",
                "enabled" :  True
            }
        }
        res = requests.post(self.host + '/v3/domains', json = body)
        self.checkCode(res, 201)

        response = res.json()
        for k, v in response.items():
            print(k, '\n\t', v)

    def test_list_domain(self):
        res = requests.get(self.host + '/v3/domains')
        self.checkCode(res, 200)

        response = res.json()
        for k, v in response.items():
            print(k, '\n\t', v)

    def test_create_project (self):
        body = {
            "project" : {
                "name": "check_project",
                "description" : "kuku",
                "enabled" :  True
            }
        }
        res = requests.post(self.host + '/v3/projects', json = body)
        self.checkCode(res, 201)

        response = res.json()
        for k, v in response.items():
            print(k, '\n\t', v)

    def test_list_project(self):
        res = requests.get(self.host + '/v3/projects')
        self.checkCode(res, 200)

        response = res.json()
        for k, v in response.items():
            print(k, '\n\t', v)

    def test_get_project_info(self):
        res = requests.get(self.host + '/v3/projects/ea0341a4-3640-4a27-9be6-fd8a78c5fefb')
        self.checkCode(res, 200)

        response = res.json()
        for k, v in response.items():
            print(k, '\n\t', v)

    def test_update_project(self):
        body = {
        "project": {
            "description": "My updated project",
            "name": "myUpdatedProject"
            }
        }
        res = requests.patch(self.host + '/v3/projects/ea0341a4-3640-4a27-9be6-fd8a78c5fefb', json=body)
        self.checkCode(res, 200)

        response = res.json()
        for k, v in response.items():
            print(k, '\n\t', v)

    def test_delete_project(self):
        res = requests.delete(self.host + '/v3/projects/cc207ed2-61e4-4e7b-ab33-6e65acc8f76c')
        self.checkCode(res, 204)
