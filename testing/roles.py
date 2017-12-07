from base import TestKeystoneBase
import requests

class TestKeystoneRoles(TestKeystoneBase):
    def setUp(self):
        super(TestKeystoneRoles, self).setUp()
        self.url = self.host + '/v3/roles/'
        self.domain_id = '7bba3639-1d1e-4999-9b14-d8392b6a025d'
        self.project_id = ''
        self.user_id = '4fac7222-87d2-41cc-9445-4e89487bfd46'
        self.group_id = ''
        self.role_id = '51c79219-bd1a-4b83-8d78-8cb27abb92ca'

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
                'name' : 'Default',
                # 'domain_id' : self.domain_id
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
        # self.res = requests.put(self.host + '/v3/projects/' + self.domain_id + '/users/' + self.user_id + '/roles/' + self.role_id, json = {}) #json object is required
        # self.checkCode(400)
        # self.res = requests.put(self.host + '/v3/domains/' + self.domain_id + '/users/' + self.user_id + '/roles/' + self.role_id, json={})  # json object is required
        # self.checkCode(204)
        self.res = requests.head(self.host + '/v3/domains/' + self.domain_id + '/users/' + self.user_id + '/roles/' + self.role_id)
        self.checkCode(204)
        # self.res = requests.delete(self.host + '/v3/domains/' + self.domain_id + '/users/' + self.user_id + '/roles/' + self.role_id)
        # self.checkCode(204)
        # self.res = requests.head(self.host + '/v3/domains/' + self.domain_id + '/users/' + self.user_id + '/roles/' + self.role_id)
        # self.checkCode(400)

    def list_implied(self):
        self.res = requests.get(self.url + self.role_id + '/implies/')
        self.checkCode(200)

    def list_2(self):
        query = {

        }
        self.res = requests.get(self.host + "/v3/role_assigments", params = query)
        self.checkCode(200)

    def list_inferences(self):
        self.res = requests.get(self.host + "/v3/role_inferences")
        self.checkCode(200)