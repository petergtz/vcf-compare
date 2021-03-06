#!/usr/bin/python

# Copyright 2013 Peter Goetz
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as published by
# the Free Software Foundation.
#  
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#    
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA


from os import listdir, makedirs, getcwd, chdir, remove, path
import os.path
from sys import argv
from subprocess import call
from shutil import rmtree


TEST_CASES_DIR = "test-cases"
DIFF_VIEWER = argv[1] if len(argv) > 1 else "meld"
SCRIPT_NAME = "vcf-compare"

def main():
    assert os.path.exists(TEST_CASES_DIR)
    num_errors = 0
    num_tests = 0
    for test_case in listdir(TEST_CASES_DIR):
        num_tests += 1
        success = run(test_case)
        if not success:  num_errors += 1
    
    print "\n" + str(num_tests) + " Tests completed. ERRORS:", num_errors
    

def run(test_case):
    print ".",
    test_run_data_dir = path.join("test-run-data", test_case)
    ensure_dir_exists_and_is_empty(test_run_data_dir)
    success = True
    with InDirectory(test_run_data_dir):
        with open("actual-output", "w") as actual_output_file, \
             open("stderr", "w") as stderr_file:
            rc = call([path.join(getcwd(), "..", "..", SCRIPT_NAME),
                       path.join("..", "..", TEST_CASES_DIR, test_case, "a.vcf"),
                       path.join("..", "..", TEST_CASES_DIR, test_case, "b.vcf")],
                      stdout= actual_output_file,
                      stderr=stderr_file)
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
