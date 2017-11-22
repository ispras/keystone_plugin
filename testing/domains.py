from base import TestKeystoneBase
import requests

class TestKeystoneDomains(TestKeystoneBase):
    def setUp(self):
        super(TestKeystoneDomains, self).setUp()
        self.host = self.host + '/v3/domains/'
    def create(self):
        body = {
            "domain" : {
                "name": "admin",
                "description" : "admin domain for testing",
                "enabled" :  True
            }
        }
        self.res = requests.post(self.host, json = body)
        self.checkCode(201)

    def delete(self):
        domain_id = '85220b62-f5cf-4fc7-adce-823e320592f4'
        self.res = requests.delete(self.host + domain_id)
        self.checkCode(204)

    def update (self):
        domain_id = '85220b62-f5cf-4fc7-adce-823e320592f4'
        body = {
        "domain": {
            "description": "My updated domain",
            "name": "myUpdatedDomain"
            }
        }
        self.res = requests.patch(self.host + domain_id, json=body)
        self.checkCode(200)

    def list(self):
        self.res = requests.get(self.host)
        self.checkCode(200)

    def get_info(self):
        domain_id = 'admin'
        self.res = requests.get(self.host + domain_id)
        self.checkCode(200)
