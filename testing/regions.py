from keystone_plugin.testing.base import TestKeystoneBase
import requests

class TestKeystoneRegions(TestKeystoneBase):
    def setUp(self):
        super(TestKeystoneRegions, self).setUp()
        self.url = self.host + '/v3/regions/'
        self.admin_auth()

    def create(self):
        body = {
            "region": {
                "description": "My region",
                "id": "RegionOne",
            }
        }
        self.res = requests.post(self.url, json = body, headers=self.headers)
        self.checkCode(201)

    def list(self):
        self.res = requests.get(self.host)
        self.checkCode(200)

    def get_info(self):
        self.res = requests.get(self.host + '/RegionOneSubRegion')
        self.checkCode(200)

    def update(self):
        body = {
            "region": {
                "description": "My subregion 3"
            }
        }
        self.res = requests.patch(self.host + '/RegionOneSubRegion', json=body)
        self.checkCode(200)

    def delete(self):
        self.res = requests.delete(self.host + '/RegionOneSubRegion1')
        self.checkCode(204)
