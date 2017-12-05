from base import TestKeystoneBase
import requests

class TestKeystoneGroups(TestKeystoneBase):
    #requires domain, role and user be created in given order

    def setUp(self):
        super(TestKeystoneGroups, self).setUp()
        self.url = self.host + '/v3/groups/'

    