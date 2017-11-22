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

    def check_assign(self):
        role_id = 'a4000abe-afc0-4770-897d-8f31fc27a3a1'
        domain_id = 'f67fa52f-eaaf-4187-a884-22e3a030d3da'
        user_id = '51672d4d-4cd0-417c-88f4-37f3364f2c7a'
        res = requests.put(self.host + '/v3/domains/' + domain_id + '/users/' + user_id + '/roles/' + role_id, json = {}) #json object is required
        self.checkCode(res, 204)
        res = requests.head(self.host + '/v3/domains/' + domain_id + '/users/' + user_id + '/roles/' + role_id)
        self.checkCode(res, 204)
        res = requests.delete(self.host + '/v3/domains/' + domain_id + '/users/' + user_id + '/roles/' + role_id)
        self.checkCode(res, 204)
        res = requests.head(self.host + '/v3/domains/' + domain_id + '/users/' + user_id + '/roles/' + role_id)
        self.checkCode(res, 210)

    def list_implied(self):
        role_id = 'a4000abe-afc0-4770-897d-8f31fc27a3a1'
        res = requests.get(self.url + role_id + '/implies/')
        self.checkCode(res, 200)
        pprint(res.json())

    def list_2(self):
        res = requests.get(self.host + "/v3/role_assigments")
        self.checkCode(res, 200)
        pprint(res.json())

    def list_inferences(self):
        res = requests.get(self.host + "/v3/role_inferences")
        self.checkCode(res, 200)
        pprint(res.json())