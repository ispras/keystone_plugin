from base import TestKeystoneBase
import requests
from pprint import pprint

class TestKeystoneRoles(TestKeystoneBase):
    def setUp(self):
        super(TestKeystoneRoles, self).setUp()
        self.url = self.host + '/v3/roles/'

    def list(self):
        query = {
            # 'name' : 'admin',
            # 'domain_id' : 'domain'
        }
        res = requests.get(self.url, params = query)
        self.checkCode(res, 200)

        pprint(res.json())

    def create(self):
        body = {
            'role' : {
                'name' : 'admin',
                # 'domain_id' : 'domain'
            }
        }
        res = requests.post(self.url, json = body)
        self.checkCode(res, 201)

        pprint(res.json())

    def get_info(self):
        role_id = 'a4000abe-afc0-4770-897d-8f31fc27a3a1'
        res = requests.get(self.url + role_id)
        self.checkCode(res, 200)

        pprint(res.json())


    def update(self):
        body = {
            'role' : {
                'name' : 'admin_1'
            }
        }
        role_id = 'a4000abe-afc0-4770-897d-8f31fc27a3a1'
        res = requests.patch(self.url + role_id, json = body)
        self.checkCode(res, 200)

        pprint(res.json())

    def delete(self):
        role_id = 'a4000abe-afc0-4770-897d-8f31fc27a3a1'
        res = requests.delete(self.url + role_id)
        self.checkCode(res, 204)

