require 'rake'
module FacilitiesManagement
  class PostcodesToNutsWorker
    include Sidekiq::Worker
    sidekiq_options queue: 'fm', retry: false, backtrace: true

    def perform
      Rake::Task.clear
      Rails.application.load_tasks
      Rake::Task['db:importpostcoderegion'].invoke
    end
  end
end
