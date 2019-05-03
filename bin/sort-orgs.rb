#!/usr/bin/ruby

# Replaces the organizations.yml file with its data sorted by name, case insensitively.
# Before overwriting the file, tests that the unsorted and sorted data,
# converted to sets, are equal.

require 'set'
require 'yaml'

def test(unsorted, sorted)
  if Set.new(unsorted) != Set.new(sorted)
    raise "Sort corrupted the data."
  end
end

def sort_orgs_case_insensitively(orgs)
  orgs.sort { |org1, org2| org1['name'].casecmp(org2['name']) }
end

def filespec
  ARGV[0] || 'organizations.yml'
end


orgs = YAML.load_file(filespec)
sorted_orgs = sort_orgs_case_insensitively(orgs)

# Enable this line to verify that the test that tests for data corruption works:
# sorted_orgs.pop 

test(orgs, sorted_orgs)
File.write(filespec, sorted_orgs.to_yaml)
