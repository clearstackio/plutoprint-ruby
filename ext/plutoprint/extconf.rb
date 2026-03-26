require "mkmf"

dir_config("plutobook")

found = pkg_config("plutobook") ||
  (find_header("plutobook.h", "/opt/homebrew/include/plutobook", "/opt/homebrew/include", "/usr/local/include", "/usr/include") &&
    find_library("plutobook", "plutobook_create", "/opt/homebrew/lib", "/usr/local/lib", "/usr/lib"))

unless found
  abort <<~MSG
    ERROR: PlutoBook library not found.

    Install PlutoBook and ensure plutobook.h and libplutobook are available.
    You can specify the installation prefix with:
      gem install plutoprint-ruby -- --with-plutobook-dir=/path/to/plutobook
  MSG
end

create_makefile("plutoprint/plutoprint")
