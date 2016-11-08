import unittest
import itertools
import subprocess
import string
PATH = "./bdd.sh"


class BDDTestCase(unittest.TestCase):
    '''
    TEST neoBDD
    '''
    def makeATest(self, params):
        self.output, self.err = subprocess.Popen(' '.join([PATH] + params),
                                       stderr=subprocess.PIPE,
                                       stdout=subprocess.PIPE,
                                       shell=True).communicate()
        return self.output

    def putTest(self, key, value):
        self.makeATest(['put', str(key), "'" + str(value) + "'"])

    def delTest(self, key, value=None):
        self.makeATest(['del', str(key), str(value)])

    def selectTest(self, value):
        return (self.makeATest(['select', str(value)]))

    def flushTest(self):
        self.makeATest(['flush'])

    def testFlush(self):
        self.flushTest()

    def testPut(self):
        self.putTest(0, "salut")

    def testSelect(self):
        self.selectTest('"*"')
        self.assertEqual(self.output, b'salut\n')

    def testDel(self):
        self.flushTest()
        self.putTest(0, "salut")
        self.putTest(1, "kikoo")
        self.delTest(1)
        self.selectTest('"*"')
        self.assertEqual(self.output, b'salut\n')

    def testx2(self):
        self.flushTest()
        dic = ['A', 'Z', 'E', 'R', 'T', 'Y']
        for key, value in enumerate(dic):
            self.putTest(key, value)
        self.selectTest('"*"')
        self.assertEqual(self.output, b'A\nZ\nE\nR\nT\nY\n')
        self.delTest(1, 'Z')
        self.selectTest('"*"')
        self.assertEqual(self.output, b'A\nE\nR\nT\nY\n')
        self.flushTest()
        self.selectTest('"*"')
        self.assertEqual(self.output, b'')

    def testy3(self):
        self.flushTest()
        word_list = []
        for xs in itertools.product(string.ascii_lowercase, repeat=2):
            word_list.append(''.join(xs))
        for key, value in enumerate(word_list):
            self.putTest(key, value)
        self.flushTest()

    def testz4(self):
        self.flushTest()
        self.putTest(0, "Hello World")
        self.putTest(1, 0)
        self.selectTest("'$1'")
        self.assertEqual(self.output, b'Hello World\n')
        self.flushTest()

    def testzzError(self):
        self.flushTest()
        self.makeATest(['put'])
        self.assertIn(b'Syntax error : put\n', self.err)
        self.makeATest(['del'])
        self.assertIn(b'Syntax error : del\n', self.err)
        self.makeATest(['select'])
        self.assertIn('', self.err)
        self.flushTest()

if __name__ == '__main__':
    unittest.main()
