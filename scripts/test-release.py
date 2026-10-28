#!/usr/bin/env python3
import importlib.util
from pathlib import Path
import unittest
import sys
sys.dont_write_bytecode = True

def load(name):
    spec=importlib.util.spec_from_file_location(name,Path(__file__).with_name(name+'.py'))
    module=importlib.util.module_from_spec(spec); spec.loader.exec_module(module); return module
validator=load('validate-release'); publisher=load('publish-release')

class ReleaseTests(unittest.TestCase):
    def test_tag_matches_stable_version(self):
        validator.validate('0.4.0','refs/tags/v0.4.0','push')
        for version,ref,event in [('0.4.0','refs/tags/v0.3.0','push'),('0.4.0-beta','refs/tags/v0.4.0-beta','push'),('0.4.0','refs/heads/feature','workflow_dispatch')]:
            with self.assertRaises(ValueError): validator.validate(version,ref,event)
    def test_dry_run_main(self):
        validator.validate('0.4.0','refs/heads/main','workflow_dispatch')
    def test_mixed_or_missing_architectures_fail(self):
        def fixtures():
            return [dict(architecture=a,version='0.4.0',sourceRevision='a'*40,signing='ad-hoc',file=f'MacTextify-0.4.0-{a}.zip',bytes=1,sha256='b'*64) for a in publisher.ARCHES]
        self.assertEqual(len(publisher.validate_manifest(fixtures(),'0.4.0','a'*40)['assets']),3)
        for field,value in [('sourceRevision','c'*40),('version','0.5.0'),('file','../other.zip'),('architecture','arm64')]:
            data=fixtures(); data[1][field]=value
            with self.assertRaises(ValueError): publisher.validate_manifest(data,'0.4.0','a'*40)
        with self.assertRaises(ValueError): publisher.validate_manifest(fixtures()[:2],'0.4.0','a'*40)

if __name__=='__main__': unittest.main()
