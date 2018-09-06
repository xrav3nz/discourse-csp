# name: DiscourseCSP
# about:
# version: 0.1
# authors: xrav3nz
# url: https://github.com/xrav3nz/discourse-csp

enabled_site_setting :discourse_csp_enabled

PLUGIN_NAME ||= "DiscourseCSP".freeze

after_initialize do
  module ::DiscourseCSP
    class Engine < ::Rails::Engine
      engine_name PLUGIN_NAME
      isolate_namespace DiscourseCSP
    end
  end

  require_dependency "application_controller"
  class ::ApplicationController
    after_action :set_csp_header

    def set_csp_header
      response.headers["Content-Security-Policy-Report-Only"] = "script-src 'self' 'unsafe-eval';"
    end
  end
end
