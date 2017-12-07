from base import TestKeystoneBase
import requests

class TestKeystoneOSINHERIT(TestKeystoneBase):
    def setUp(self):
        super(TestKeystoneOSINHERIT, self).setUp()
        self.url = self.host + '/v3/OS-INHERIT/'
        self.domain_id = '7bba3639-1d1e-4999-9b14-d8392b6a025d'
        self.project_id = ''
        self.user_id = '4fac7222-87d2-41cc-9445-4e89487bfd46'
        self.group_id = ''
        self.role_id = '51c79219-bd1a-4b83-8d78-8cb27abb92ca'
        self.du_url = self.url + 'domains/' + self.domain_id + '/users/' + self.user_id + '/roles/inherited_to_projects'
        self.dg_url = self.url + 'domains/' + self.domain_id + '/groups/' + self.group_id + '/roles/inherited_to_projects'
        self.dur_url = self.url + 'domains/' + self.domain_id + '/users/' + self.user_id + '/roles/' + self.role_id + '/inherited_to_projects'
        self.dgr_url = self.url + 'domains/' + self.domain_id + '/groups/' + self.group_id + '/roles/' + self.role_id + '/inherited_to_projects'
        self.pur_url = self.url + 'projects/' + self.project_id + '/users/' + self.user_id + '/roles/' + self.role_id + '/inherited_to_projects'
        self.pgr_url = self.url + 'projects/' + self.project_id + '/groups/' + self.group_id + '/roles/' + self.role_id + '/inherited_to_projects'

    def assign(self):
        self.res = requests.put(self.dur_url, json = {})
        self.checkCode(204)

    def list(self):
        self.res = requests.get(self.du_url)
        self.checkCode(200)

    def list_all(self):
        query = {
            'scope.OS-INHERIT.inherited_to' : 'projects'
        }
        self.res = requests.get(self.host + "/v3/role_assigments", params=query)
        self.checkCode(200)

    def check(self):
        self.res = requests.head(self.dur_url)
        self.checkCode(204)

    def unassign(self):
        self.res = requests.delete(self.dur_url)
        self.checkCode(204)