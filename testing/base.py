import unittest
from pprint import pprint

class TestKeystoneBase(unittest.TestCase):
    def setUp(self):
        super(TestKeystoneBase, self).setUp()
        self.host = 'http://localhost:8001'
    def checkCode(self, code):
        if self.res.status_code != code:
            try:
                print("Failed with error:", self.res.reason)
                response = self.res.json()
                for k, v in response.items():
                    print(k, '\n\t', v)
            except Exception:
                print("Failed with error:", self.res.reason)
            self.assertEqual(self.res.status_code, code)
    def tearDown(self):
        try:
            pprint(self.res.json())
        except:
            pass