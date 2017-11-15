import unittest

class TestKeystoneBase(unittest.TestCase):
    def setUp(self):
        super(TestKeystoneBase, self).setUp()
        self.host = 'http://localhost:8001'
    def checkCode(self, res, code):
        if res.status_code != code:
            try:
                print("Failed with error:", res.reason)
                response = res.json()
                for k, v in response.items():
                    print(k, '\n\t', v)
            except Exception:
                print("Failed with error:", res.reason)
            self.assertEqual(res.status_code, code)
