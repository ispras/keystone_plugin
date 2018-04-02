from base import TestKeystoneBase
import requests

class TestKeystoneDomains(TestKeystoneBase):
    def setUp(self):
        super(TestKeystoneDomains, self).setUp()
        self.url = self.host + '/v3/domains/'
        self.domain_id = ''
        # self.admin_auth()

    def create(self):
        body = {
            "domain": {
                "name": "test",
                "description": "test domain for testing",
                "enabled":  True
            }
        }
        self.res = requests.post(self.url, json = body, headers = self.headers)
        self.checkCode(201)

    def delete(self):
        self.res = requests.delete(self.url + 'e039085c-416c-4b2f-9c52-e4706c87bec4', headers = self.headers)
        self.checkCode(204)

    def update (self):
        body = {
        "domain": {
            "description": "My updated domain",
            "name": "myUpdatedDomain"
            }
        }
        self.res = requests.patch(self.url + self.domain_id, json=body, headers = self.headers)
        self.checkCode(200)

    def list(self):
        self.headers['X-Auth-Token'] = 'gAAAAABawgq1Q-ivIcihF71YJZyEn-0KljJBHIpP2bEJyrVSEUQeSSSv6wXViZHw2ouZ8fa4hP6sS8v-NHUN2WRRrGHJk0TRbf-N_LX4TPrAgOQ3620T7k4='
        query = {
            'name' : 'Default'
        }
        self.res = requests.get(self.url, params = query, headers = self.headers)
        self.checkCode(200)

    def get_info(self):
        self.res = requests.get(self.url + self.domain_id, headers = self.headers)
        self.checkCode(200)
