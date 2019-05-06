#!/usr/bin/ruby

# Replaces the organizations.yml file with its data sorted by name, case insensitively.
# Before overwriting the file, tests that the unsorted and sorted data,
# converted to sets, are equal.

require 'set'
require 'yaml'

def orgs_filespec
  @orgs_filespec ||= begin
    project_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))
    File.join(project_root, 'data', 'seeds', 'organizations.yml')
  end
end


def test(unsorted, sorted)
  if Set.new(unsorted) != Set.new(sorted)
    raise "Sort corrupted the data."
  end
end


def sort_orgs_case_insensitively(orgs)
  orgs.sort { |org1, org2| org1['name'].casecmp(org2['name']) }
end


def main
  orgs = YAML.load_file(orgs_filespec)
  sorted_orgs = sort_orgs_case_insensitively(orgs)

  if orgs == sorted_orgs
    puts "File was already sorted. No need to overwrite."
    exit(0)
  else

    # Enable this line to verify that the test that tests for data corruption works:
    # sorted_orgs.pop

    test(orgs, sorted_orgs)
    File.write(orgs_filespec, sorted_orgs.to_yaml)
    puts "Organizations file sort successful."
  end
end


main
