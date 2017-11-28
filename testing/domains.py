from base import TestKeystoneBase
import requests

class TestKeystoneDomains(TestKeystoneBase):
    def setUp(self):
        super(TestKeystoneDomains, self).setUp()
        self.host = self.host + '/v3/domains/'
        self.domain_id = ''

    def create(self):
        body = {
            "domain" : {
                "name": "default_domain",
                "description" : "admin domain for testing",
                "enabled" :  True
            }
        }
        self.res = requests.post(self.host, json = body)
        self.checkCode(201)

    def delete(self):
        self.res = requests.delete(self.host + self.domain_id)
        self.checkCode(204)

    def update (self):
        body = {
        "domain": {
            "description": "My updated domain",
            "name": "myUpdatedDomain"
            }
        }
        self.res = requests.patch(self.host + self.domain_id, json=body)
        self.checkCode(200)

    def list(self):
        self.res = requests.get(self.host)
        self.checkCode(200)

    def get_info(self):
        self.res = requests.get(self.host + self.domain_id)
        self.checkCode(200)
