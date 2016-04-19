# Cody Herriges <cody@puppetlabs.com>
# Johan Haals <johan.haals@gmail.com> (Darwin: https://github.com/jhaals/jhaals-app_inventory)
# Andrew Wippler <andrew.wippler@gmail.com> (Windows)
# Jonathan Dowland (Variable name fixes)
#
# Collects and creates a fact for every package installed on the system and
# returns that package's version as the fact value.  Useful for doing package
# inventory and making decisions based on installed package versions.

require 'facter/util/pkg'

Facter::Util::Pkg.package_list.each do |key, value|
  Facter.add(:"pkg_#{key}") do
    confine :operatingsystem => %w{CentOS Fedora Redhat Debian Ubuntu Solaris windows Darwin}
    setcode do
      value
    end
  end
end
