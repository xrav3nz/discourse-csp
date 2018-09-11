# name: discourse-csp
# about:
# version: 0.1
# authors: xrav3nz
# url: https://github.com/xrav3nz/discourse-csp

enabled_site_setting :discourse_csp_enabled

PLUGIN_NAME ||= "DiscourseCsp".freeze

after_initialize do
  module ::DiscourseCsp
    class Engine < ::Rails::Engine
      engine_name PLUGIN_NAME
      isolate_namespace DiscourseCsp
    end
  end

  require_dependency "application_controller"
  class ::ApplicationController
    after_action :set_csp_header

    def set_csp_header
      response.headers["Content-Security-Policy-Report-Only"] = "script-src 'self' 'unsafe-eval'; report-uri /discourse-csp/reports"
    end
  end

  class DiscourseCsp::ReportsController < ::ApplicationController
    requires_plugin PLUGIN_NAME

    skip_before_action :check_xhr, :preload_json, :verify_authenticity_token, only: [:create]

    def create
      report = JSON.parse(request.body.read)['csp-report']

      Logster.add_to_env(request.env, 'CSP Report', report)
      Rails.logger.error("CSP Violation: '#{report['blocked-uri']}'")

      head :ok
    end
  end

  DiscourseCsp::Engine.routes.draw do
    resources :reports, only: [:create]
  end

  Discourse::Application.routes.append do
    mount ::DiscourseCsp::Engine, at: 'discourse-csp'
  end
end
