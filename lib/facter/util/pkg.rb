# Cody Herriges <cody@puppetlabs.com>
# Johan Haals <johan.haals@gmail.com> (Darwin: https://github.com/jhaals/jhaals-app_inventory)
# Andrew Wippler <andrew.wippler@gmail.com> (Windows)
# Jonathan Dowland (Variable name fixes)
#
# Collects and creates a fact for every package installed on the system and
# returns that package's version as the fact value.  Useful for doing package
# inventory and making decisions based on installed package versions.

require 'rexml/document'
include REXML

module Facter::Util::Pkg
  def self.validname(name)
    name = name.tr('-+.','_') # RPM and deb packages might contain these
    name = name.sub(/:.*/,'') # Debian multiarch arch qualifiers
    name
  end

  def self.parse(element)
    case element.name
    when 'array'
      element.elements.map {|child| parse(child)}
    when 'dict'
      result = {}
      element.elements.each_slice(2) do |key, value|
        result[key.text] = parse(value)
      end
      result
    when 'real'
      element.text.to_f
    when 'integer'
      element.text.to_i
    when 'string', 'date'
      element.text
    end
  end

  def self.package_list
    packages = []
    case Facter.value(:operatingsystem)
    when 'Debian', 'Ubuntu'
      command = 'dpkg-query -W'
      packages = []
      Facter::Util::Resolution.exec(command).each_line do |pkg|
        name,version = pkg.chomp.split("\t")
        packages << [Facter::Util::Pkg::validname(name),version]
      end
    when 'CentOS', 'RedHat', 'Fedora'
      command = 'rpm -qa --qf %{NAME}"\t"%{VERSION}-%{RELEASE}"\n"'
      packages = []
      Facter::Util::Resolution.exec(command).each_line do |pkg|
        name,version = pkg.chomp.split("\t")
        packages << [Facter::Util::Pkg::validname(name),version]
        end
    when 'windows'
      command = 'wmic product get name,version /format:csv'
      packages = []
      Facter::Util::Resolution.exec(command).each_line do |pkg|
        packages << pkg.chomp.split(",").drop(1)
      end
    when 'Darwin'
      xml = Facter::Util::Resolution.exec('system_profiler SPApplicationsDataType -xml')
      xmldoc = Document.new(xml)
      command = Facter::Util::Pkg::parse(xmldoc.root[1])
      packages = []
      command[0]['_items'].each do |pkg|
        if pkg['path'].match(/^\/Applications/) and pkg['path'].index('Utilities') == nil
          if !pkg['version'].nil?
            packages << [pkg['_name'].downcase.gsub(' ',''),pkg['version']]
          end
        end
      end
    when 'Solaris'
      command = 'pkginfo -x'
      combined = ''
      packages = []
      Facter::Util::Resolution.exec(command).each_line do |line|
        if line =~ /^\w/
          then
            combined << line.chomp
          else
            combined << line
        end
      end
      combined.each_line do |pkg|
        packages << pkg.chomp.scan(/^(\S+).*\s(\d.*)/)[0]
      end
    end
    return packages
  end
end

