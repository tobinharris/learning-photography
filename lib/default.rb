# All files in the 'lib' directory will be loaded
# before nanoc starts compiling.

# require 'lib/helpers/toc'
# require 'lib/helpers/compile-book'
# require 'lib/filters/image_paths'
# require 'lib/filters/kramdown_tex'
# require 'lib/filters/pdf_fixes'
# require 'lib/helpers/blogging'

Dir[File.join(".", "**/*.rb")].each do |f|
    require f
end
    
# Helpers
include Nanoc3::Helpers::LinkTo
include Nanoc3::Helpers::Breadcrumbs
include Nanoc3::Helpers::Blogging
include TocHelper
include CompileBookHelper
