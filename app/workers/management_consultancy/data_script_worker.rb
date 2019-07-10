require 'rake'
require 'aws-sdk-s3'

module ManagementConsultancy
  class DataScriptWorker
    include Sidekiq::Worker

    def perform(upload_id)
      upload = ManagementConsultancy::Admin::Upload.find(upload_id)
      Rake::Task.clear
      Rails.application.load_tasks
      Rake::Task['mc:clean'].invoke
      Rake::Task['mc:data'].invoke

      begin
        if File.zero?(error_file_path)
          upload.review!
        else
          file = File.open(error_file_path)
          fail_upload(upload, 'There is an error with your files: ' + file.read)
        end
      rescue StandardError => e
        fail_upload(ManagementConsultancy::Admin::Upload.find(upload_id), 'There is an error with your files. Please try again. ' + e.message)
      end
    end

    private

    def fail_upload(upload, fail_reason)
      upload.fail!
      upload.update(fail_reason: fail_reason)
    end

    def error_file_path
      file_path = 'storage/management_consultancy/current_data/output/errors.out'
      return file_path if Rails.env.development?

      object = Aws::S3::Resource.new(region: ENV['COGNITO_AWS_REGION'])
      object.bucket(ENV['CCS_APP_API_DATA_BUCKET']).object(s3_path(file_path))
    end
  end
end
