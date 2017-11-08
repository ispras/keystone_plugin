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

    def test_create_domain (self):
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

