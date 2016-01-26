# Copyright 2003-2010 by Jim Weirich (jim.weirich@gmail.com)
# All rights reserved.

# :stopdoc:

# Configuration information about an upload host system.
# name   :: Name of host system.
# webdir :: Base directory for the web information for the
#           application.  The application name (APP) is appended to
#           this directory before using.
# pkgdir :: Directory on the host system where packages can be
#           placed.
HostInfo = Struct.new(:name, :webdir, :pkgdir)

# :startdoc:

# TODO: Move to contrib/sshpublisher
#--
# Manage several publishers as a single entity.
class CompositePublisher # :nodoc:
  def initialize
    @publishers = []
  end

  # Add a publisher to the composite.
  def add(pub)
    @publishers << pub
  end

  # Upload all the individual publishers.
  def upload
    @publishers.each { |p| p.upload }
  end
end
