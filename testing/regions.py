from base import TestKeystoneBase
import requests

class TestKeystoneRegions(TestKeystoneBase):
    def setUp(self):
        super(TestKeystoneRegions, self).setUp()
        self.host = self.host + '/v3/regions/'

    def create(self):
        body = {
            "region": {
                "description": "My subregion",
                "id": "RegionOne",
            }
        }
        res = requests.post(self.host, json = body)
        self.checkCode(res, 201)

        response = res.json()
        for k, v in response.items():
            print(k, '\n\t', v)

    def list(self):
        res = requests.get(self.host)
        self.checkCode(res, 200)

        response = res.json()
        for k, v in response.items():
            print(k, '\n\t', v)

    def get_info(self):
        res = requests.get(self.host + '/RegionOneSubRegion')
        self.checkCode(res, 200)

        response = res.json()
        for k, v in response.items():
            print(k, '\n\t', v)

    def update(self):
        body = {
            "region": {
                "description": "My subregion 3"
            }
        }
        res = requests.patch(self.host + '/RegionOneSubRegion', json=body)
        self.checkCode(res, 200)

        response = res.json()
        for k, v in response.items():
            print(k, '\n\t', v)

    def delete(self):
        res = requests.delete(self.host + '/RegionOneSubRegion1')
        self.checkCode(res, 204)
