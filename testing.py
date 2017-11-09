import requests
import unittest
import json

class TestKeystone(unittest.TestCase):
    host = 'http://localhost:8001'
    def checkCode(self, res, code):
        if res.status_code != code:
            try:
                print("Failed with error:", res.reason, res.json())
            except Exception:
                print("Failed with error:", res.reason)
            self.assertEqual(res.status_code, code)

    def test_list_users(self):
        query = {
            # 'domain_id' : 'domain_id',
            'enabled': 'true',
            'idp_id': 'idp_id',
            'name': 'name',
            'password_expires_at': 'password_expires_at',
            'protocol_id': 'protocol_id',
            'unique_id': 'unique_id'
        }
        res = requests.get(self.host + '/v3/users', params = query)
        self.checkCode(res, 200)
        response = res.json()
        print(response['links']['self'])
        for key, val in response['users'].items():
            print('\t', key, ':', val)

    def test_create_user(self):
        body = {
            "user": {
                "default_project_id": "default_project_id",
                "domain_id": "domain_id",
                "enabled": "true",
                "name": "admin",
                "password": "tester"
            }
        }
        res = requests.post(self.host + '/v3/users', json = body)
        self.checkCode(res, 200)

        response = res.json()
        self.assertTrue(bool(response['user']['enabled']))

        self.user_id = response['user']['id']

    def test_create_domain(self):
        body = {
            "domain" : {
                "name": "valerius_domain",
                "description" : "kuku",
                "enabled" :  True
            }
        }
        res = requests.post(self.host + '/v3/domains', json = body)
        self.checkCode(res, 201)

        response = res.json()
        print(response)

    def test_list_domain(self):
        res = requests.get(self.host + '/v3/domains')
        self.checkCode(res, 200)

        response = res.json()
        for k, v in response.items():
            print(k, '\n\t', v)

    def test_create_project(self):
        body = {
        "project": {
            "description": "New project",
            "enabled": True,
            "is_domain": False,
            "name": "NewProject2"
        }
}
        res = requests.post(self.host + '/v3/projects', json = body)
        self.checkCode(res, 201)

        response = res.json()
        print(response)

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
        print(response)

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
        print(response)

    def test_delete_project(self):
        res = requests.delete(self.host + '/v3/projects/cc207ed2-61e4-4e7b-ab33-6e65acc8f76c')
        self.checkCode(res, 204)
