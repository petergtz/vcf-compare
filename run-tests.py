#!/usr/bin/python

from os import listdir, makedirs, getcwd, chdir, remove
import os.path
from os import path
from sys import argv
from subprocess import call
from shutil import rmtree
import sys


TEST_CASES_DIR = "test-cases"
DIFF_VIEWER = argv[1] if len(argv) > 1 else "meld"


def main():
    assert os.path.exists(TEST_CASES_DIR)
    num_errors = 0
    for test_case in listdir(TEST_CASES_DIR):
        success = run(test_case)
        if not success:  num_errors += 1
    
    print "\nTests completed. ERRORS:", num_errors
    

def run(test_case):
    print ".",
    test_run_data_dir = path.join("test-run-data", test_case)
    ensure_dir_exists_and_is_empty(test_run_data_dir)
    success = True
    with InDirectory(test_run_data_dir):
        rc = call([path.join(getcwd(), "..", "..", "vcf_compare.pl"), 
                   path.join("..", "..", TEST_CASES_DIR, test_case, "a.vcf"),
                   path.join("..", "..", TEST_CASES_DIR, test_case, "b.vcf")],
                  stdout=open("actual-output", "w"),
                  stderr=open("stderr", "w"))
        if rc != 0:
            print error(test_case, "script returned error. RC = " + str(rc))
            success = False
        else:
            actual_output_filename = "actual-output"
            expected_output_filename = path.join("..", "..", TEST_CASES_DIR, test_case, "expected-output")
            with open(actual_output_filename) as actual_output_file, \
                 open(expected_output_filename) as expected_output_file:
                if actual_output_file.read() != expected_output_file.read():
                    success = False
                    print error(test_case, "Files differ. Running diff\n")
                    call([DIFF_VIEWER, actual_output_filename, expected_output_filename])
                    print "\nEnd of Diff\n"
    
    if success: rmtree(test_run_data_dir)
    return success
    
    
def ensure_dir_exists_and_is_empty(path):
    if os.path.exists(path): rmtree(path)
    makedirs(path)
    
def error(test_case, message):
    return "\nIn " + test_case + ": " + message
    
class InDirectory:
    def __init__(self, new_path):
        self.new_path = new_path

    def __enter__(self):
        self.saved_path = os.getcwd()
        os.chdir(self.new_path)

    def __exit__(self, etype, value, traceback):
        os.chdir(self.saved_path)    
    
if __name__ == "__main__":
    main()
