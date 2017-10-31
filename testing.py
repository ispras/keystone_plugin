import requests
import unittest
import json

class TestKeystone(unittest.TestCase):
    host = 'http://localhost:8001'
    def checkCode(self, res, code):
        if res.status_code != 200:
            print("Failed with error:", res.reason, res.json())
            self.assertEqual(res.status_code, code)
    def test_version(self):
        res = requests.get(self.host + '/v2.0')
        self.checkCode(res, 200)
        response = res.json()
        for key, val in response['version'].items():
            print('\t', key, ':', val)

    def test_create_tenant(self):
        body = {
            "tenant" : {
                "name" : "admin"
            }
        }
        res = requests.post(self.host + '/v2.0/tenants', json = body)
        self.checkCode(res, 200)

        response = res.json()
        self.tenant_id = response['tenant']['id']

    def test_create_user(self):
        body = {
            "user": {
                "name": "admin",
                "tenantId": self.tenant_id,
                "password": "tester",
                "email": "some@email.com"
            }
        }
        res = requests.post(self.host + '/v2.0/users', json = body)
        self.checkCode(res, 200)

        response = res.json()
        self.assertTrue(bool(response['user']['enabled']))

        self.user_id = response['user']['id']

    def test_user_info(self):
        res = requests.get(self.host + '/v2.0/users/:' + self.user_id)
        self.checkCode(res, 200)

        response = res.json()
        for key, val in response['user'].items():
            print('\t', key, ':', val)

    def test_receive_token(self):
        body = {
            "auth": {
                "passwordCredentials": {
                    "username": "admin",
                    "password": "tester"
                },
                "tenantName": "admin"
            }
        }
        res = requests.post(self.host + '/v2.0/tokens', json = body)
        self.checkCode(res, 200)

        response = res.json()
        for key, val in response['auth'].items():
            print('\t', key, ':', val)

    def test_delete_user(self):
        res = requests.delete(self.host + '/v2.0/users/:' + self.user_id)
        self.checkCode(res, 200)


    def test_delete_tenant(self):
        res = requests.delete(self.host + '/v2.0/tenants/:' + self.tenant_id)
        self.checkCode(res, 200)

