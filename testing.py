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


class TestKeystoneUser(TestKeystone):
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

    def create_local(self):
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

    def create_nonlocal(self):
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

    def delete(self):
        user_id = 'bfeef63f-ff7e-446b-95a5-66b8a2c06710'
        res = requests.delete(self.host + '/v3/users/' + user_id)
        self.checkCode(res, 204)

    def get_info(self):
        user_id = '730fbea0-ed5f-47f4-a86c-8296481422e7'
        res = requests.get(self.host + '/v3/users/' + user_id)
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
        user_id = 'bfeef63f-ff7e-446b-95a5-66b8a2c06710'
        body = {
            "user" : {
                'enabled': True,
                'name' : 'check',
                'password' : 'secret2'
            }
        }
        res = requests.patch(self.host + '/v3/users/' + user_id, json = body)
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
        res = requests.get(self.host + '/v3/users/' + user_id + '/groups')
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
        res = requests.get(self.host + '/v3/users/' + user_id + '/projects')
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
        res = requests.post(self.host + '/v3/users/' + user_id + '/password', json = body)
        self.checkCode(res, 204)

class TestKeystoneDomain(TestKeystone):
    def create(self):
        body = {
            "domain" : {
                "name": "default_domain",
                "description" : "kuku",
                "enabled" :  True
            }
        }
        res = requests.post(self.host + '/v3/domains', json = body)
        self.checkCode(res, 201)

        response = res.json()
        for k, v in response.items():
            print(k, '\n\t', v)

    def list(self):
        res = requests.get(self.host + '/v3/domains')
        self.checkCode(res, 200)

        response = res.json()
        for k, v in response.items():
            print(k, '\n\t', v)

class TestKeystoneProject(TestKeystone):
    def create (self):
        body = {
        "domain": {
            "description": "My updated domain",
            "name": "myUpdatedDomain"
            }
        }
        res = requests.patch(self.host + '/v3/domains/85220b62-f5cf-4fc7-adce-823e320592f4', json=body)
        self.checkCode(res, 200)

        response = res.json()
        for k, v in response.items():
            print(k, '\n\t', v)

    def test_delete_domain(self):
        res = requests.delete(self.host + '/v3/domains/85220b62-f5cf-4fc7-adce-823e320592f4')
        self.checkCode(res, 204)

    def test_create_project(self):
        body = {
        "project": {
            "description": "New project",
            "enabled": True,
            "is_domain": False,
            "name": "NewProject3"
            }
        }
        res = requests.post(self.host + '/v3/projects', json = body)
        self.checkCode(res, 201)

        response = res.json()
        for k, v in response.items():
            print(k, '\n\t', v)

    def list(self):
        res = requests.get(self.host + '/v3/projects')
        self.checkCode(res, 200)

        response = res.json()
        for k, v in response.items():
            print(k, '\n\t', v)

    def get_info(self):
        res = requests.get(self.host + '/v3/projects/ea0341a4-3640-4a27-9be6-fd8a78c5fefb')
        self.checkCode(res, 200)

        response = res.json()
        for k, v in response.items():
            print(k, '\n\t', v)

    def update(self):
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

    def delete(self):
        res = requests.delete(self.host + '/v3/projects/cc207ed2-61e4-4e7b-ab33-6e65acc8f76c')
        self.checkCode(res, 204)

    def test_create_region(self):
        body = {
            "region": {
                "description": "My subregion",
                "id": "RegionOneSubRegion2",
                "parent_region_id": "RegionOneSubRegion1"
            }
        }
        res = requests.post(self.host + '/v3/regions', json = body)
        self.checkCode(res, 201)

        response = res.json()
        for k, v in response.items():
            print(k, '\n\t', v)

    def test_list_region(self):
        res = requests.get(self.host + '/v3/regions')
        self.checkCode(res, 200)

        response = res.json()
        for k, v in response.items():
            print(k, '\n\t', v)

    def test_get_region_info(self):
        res = requests.get(self.host + '/v3/regions/RegionOneSubRegion')
        self.checkCode(res, 200)

        response = res.json()
        for k, v in response.items():
            print(k, '\n\t', v)

    def test_update_region(self):
        body = {
            "region": {
                "description": "My subregion 3"
            }
        }
        res = requests.patch(self.host + '/v3/regions/RegionOneSubRegion', json=body)
        self.checkCode(res, 200)

        response = res.json()
        for k, v in response.items():
            print(k, '\n\t', v)

    def test_delete_region(self):
        res = requests.delete(self.host + '/v3/regions/RegionOneSubRegion1')
        self.checkCode(res, 204)

    def test_create_service(self):
        body = {
            "service": {
                "type": "compute",
                "name": "compute2",
                "description": "Compute service 2"
            }
        }
        res = requests.post(self.host + '/v3/services', json = body)
        self.checkCode(res, 201)

        response = res.json()
        for k, v in response.items():
            print(k, '\n\t', v)

class TestKeystoneAuthAndTokens(TestKeystone):
    def password_unscoped(self):
        body = {
            'auth' : {
                'identity' : {
                    'methods' : [ 'password' ],
                    'password' : {
                        'user' : {
                            'name' : 'admin',
                            'domain' : {
                                'name' : 'default_domain'
                            },
                            'password' : 'new_tester'
                        }
                    }
                }
            }
        }
        res = requests.post(self.host + '/v3/auth/tokens', json = body)
        self.checkCode(res, 201)


        response = res.json()
        for k, v in response['token'].items():
            print(k, '\n\t', v)

class TestKeystoneService(TestKeystone):
    def test_list_services(self):
        res = requests.get(self.host + '/v3/services')
        self.checkCode(res, 200)

        response = res.json()
        for k, v in response.items():
            print(k, '\n\t', v)

    def test_get_service_info(self):
        res = requests.get(self.host + '/v3/services/63f7baeb-b038-4883-8c2a-e6414d58b758')
        self.checkCode(res, 200)

        response = res.json()
        for k, v in response.items():
            print(k, '\n\t', v)

    def test_update_service(self):
        body = {
        "service": {
            "description": "Block Storage Service V2"
            }
        }
        res = requests.patch(self.host + '/v3/services/63f7baeb-b038-4883-8c2a-e6414d58b758', json=body)
        self.checkCode(res, 200)

        response = res.json()
        for k, v in response.items():
            print(k, '\n\t', v)

    def test_delete_service(self):
        res = requests.delete(self.host + '/v3/services/63f7baeb-b038-4883-8c2a-e6414d58b758')
        self.checkCode(res, 204)
