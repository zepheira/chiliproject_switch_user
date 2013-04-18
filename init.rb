require 'redmine'

# stackoverflow.com/questions/7936023/
require 'dispatcher'

Dispatcher.to_prepare do
  ApplicationController.send(:include, SwitchUser::Patches::ApplicationPatch) unless ApplicationController.include?(SwitchUser::Patches::ApplicationPatch)
end

Redmine::Plugin.register :chiliproject_switch_user do
  name 'Chiliproject Switch User Plugin'
  author 'Ryan Lee'
  description 'Allow X-ChiliProject-Switch-User header in REST API'
  version '0.0.1'
  url 'https://github.com/zepheira/chiliproject_switch_user'
  author_url 'http://zepheira.com/people/ryan-lee/'
end
