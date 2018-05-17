from keystone_plugin.testing.base import TestKeystoneBase
import requests

class TestKeystoneRoles(TestKeystoneBase):
    def setUp(self):
        super(TestKeystoneRoles, self).setUp()
        self.url = self.host + '/v3/roles/'
        self.domain_id = 'default'
        self.project_id = '23ba7123-81ab-45d1-bc37-4bbfc70a1da1'
        self.user_id = '92fcb6a7-baa1-41d8-8814-5e13f4e7fb1f'
        self.group_id = ''
        self.role_id = '2df7b2c7-e3bd-4faf-baff-e1368a8cff0b'
        self.admin_auth()

    def list(self):
        query = {
            # 'name' : 'admin',
            # 'domain_id' : 'domain'
        }
        self.res = requests.get(self.url, params = query, headers = self.headers)
        self.checkCode(200)

    def create(self):
        body = {
            'role' : {
                'name' : 'admin',
                'domain_id' : self.domain_id
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
        self.headers['Content-Type'] = 'application/json'
        self.headers['X-Auth-Token'] = 'gAAAAABawijrQYMCx3o9A531P-4kq91EX6cnFVzJTMkShWFSn35uJIho6tNQyZSX6BLDzoRqEjmDBN745gZN3ldQ9FTHmaF9MVbn61-O2eWMDNj7nOqSU85_T6BrUGU8fuczlRTJ26oH'
        self.res = requests.put(self.host + '/v3/projects/' + self.project_id + '/users/' + self.user_id + '/roles/' + self.role_id, headers = self.headers)
        self.checkCode(204)
        # self.res = requests.get(self.host + '/v3/projects/' + self.project_id + '/users/' + self.user_id + '/roles/', headers = self.headers) #json object is required
        # self.checkCode(200)
        # self.res = requests.put(self.host + '/v3/domains/' + self.domain_id + '/users/' + self.user_id + '/roles/' + self.role_id, json={})  # json object is required
        # self.checkCode(204)
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
        query = {
            'project_id' : self.project_id,
            'user_id' : self.user_id
        }
        self.res = requests.get(self.host + "/v3/role_assignments", params = query, headers = self.headers)
        self.checkCode(200)

    def list_inferences(self):
        self.res = requests.get(self.host + "/v3/role_inferences")
        self.checkCode(200)

    def list_as(self):
        # self.res = requests.get(self.host + '/v3/domains/' + self.domain_id + '/users/' + self.user_id + '/roles')
        # self.checkCode(200)
        self.admin_domain_id = '075895d8-7134-4c92-989a-c413b181236f'
        self.admin_user_id = '1ce60175-8d39-4c73-b247-2da9675fc094'
        self.admin_role_id = 'a490cc5a-9a6f-49c5-b8c9-24d865a23017'
        # self.res = requests.put(self.host + '/v3/domains/' + self.admin_domain_id + '/users/'
        #                        + self.admin_user_id + '/roles/' + self.admin_role_id,
        #                        json={})  # json object is required
        # self.checkCode(204)
        # self.res = requests.get(self.host + '/v3/domains/' + self.admin_domain_id + '/users/' + self.admin_user_id + '/roles')
        # self.checkCode(200)
        self.admin_project_id = 'd890d7e8-b951-4133-8045-0a8493c059c8'
        self.res = requests.put(
            self.host + '/v3/projects/' + self.admin_project_id + '/users/' + self.admin_user_id + '/roles/' + self.admin_role_id,
            json={})  # json object is required
        self.checkCode(204)
