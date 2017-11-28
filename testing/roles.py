from base import TestKeystoneBase
import requests

class TestKeystoneRoles(TestKeystoneBase):
    def setUp(self):
        super(TestKeystoneRoles, self).setUp()
        self.url = self.host + '/v3/roles/'
        self.role_id = 'a4000abe-afc0-4770-897d-8f31fc27a3a1'
        self.domain_id = 'f67fa52f-eaaf-4187-a884-22e3a030d3da'
        self.user_id = '51672d4d-4cd0-417c-88f4-37f3364f2c7a'

    def list(self):
        query = {
            # 'name' : 'admin',
            # 'domain_id' : 'domain'
        }
        self.res = requests.get(self.url, params = query)
        self.checkCode(200)

    def create(self):
        body = {
            'role' : {
                'name' : 'admin',
                # 'domain_id' : 'domain'
            }
        }
        self.res = requests.post(self.url, json = body)
        self.checkCode(201)

    def get_info(self):
        self.res = requests.get(self.url + self.role_id)
        self.checkCode(200)


    def update(self):
        body = {
            'role' : {
                'name' : 'admin_1'
            }
        }
        self.res = requests.patch(self.url + self.role_id, json = body)
        self.checkCode(200)

    def delete(self):
        self.res = requests.delete(self.url + self.role_id)
        self.checkCode(204)

    def check_assign(self):
        self.res = requests.put(self.host + '/v3/projects/' + self.domain_id + '/users/' + self.user_id + '/roles/' + self.role_id, json = {}) #json object is required
        self.checkCode(400)
        self.res = requests.put(self.host + '/v3/domains/' + self.domain_id + '/users/' + self.user_id + '/roles/' + self.role_id, json={})  # json object is required
        self.checkCode(204)
        # self.res = requests.head(self.host + '/v3/domains/' + self.domain_id + '/users/' + self.user_id + '/roles/' + self.role_id)
        # self.checkCode(204)
        # self.res = requests.delete(self.host + '/v3/domains/' + self.domain_id + '/users/' + self.user_id + '/roles/' + self.role_id)
        # self.checkCode(204)
        # self.res = requests.head(self.host + '/v3/domains/' + self.domain_id + '/users/' + self.user_id + '/roles/' + self.role_id)
        # self.checkCode(400)

    def list_implied(self):
        self.res = requests.get(self.url + self.role_id + '/implies/')
        self.checkCode(200)

    def list_2(self):
        self.check_assign()
        self.check_assign()
        self.res = requests.get(self.host + "/v3/role_assigments")
        self.checkCode(200)

    def list_inferences(self):
        self.res = requests.get(self.host + "/v3/role_inferences")
        self.checkCode(200)