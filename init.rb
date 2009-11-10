require 'redmine'

Dir::foreach(File.join(File.dirname(__FILE__), 'lib')) do |file|
  next unless /\.rb$/ =~ file
  require file
end

config.frameworks -= [ :active_record, :active_resource, :action_mailer ]
config.gem 'gdata', :lib => 'gdata'



Redmine::Plugin.register :redmine_googledocs do
  name 'Redmine Googledocs plugin'
  author 'Paul L. D. Roberts'
  description 'Add Google Docs to redmine (create and edit)'
  version '0.0.1'

  project_module :googledocs do
    permission :view_googledocs, :googledocs => :list
    permission :edit_googledocs, :googledocs => :edit
    permission :create_googledocs, :googledocs => :new
    permission :delete_googledocs, :googledocs => :delete
  end
  menu :project_menu, :googeldocs, { :controller => 'googledocs', :action => 'list' }, :caption => 'Google Docs', :after => :activity, :param => :project_id

end
