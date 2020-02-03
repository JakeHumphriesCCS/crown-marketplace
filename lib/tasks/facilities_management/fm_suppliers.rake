module CCS
  require 'pg'
  require 'csv'
  require 'json'
  require 'roo'
  require Rails.root.join('lib', 'tasks', 'distributed_locks')

  def self.supplier_data
    is_dev_db = ENV['CCS_DEFAULT_DB_HOST']
    # debug
    puts "CCS_DEFAULT_DB_HOST #{is_dev_db}"
    # nb reinstate || (is_dev_db.include? 'dev')
    if is_dev_db.nil? || (%w[dev. cmpdefault.db.internal.fm-preview marketplace.preview sandbox].any? { |env| is_dev_db.include?(env) })
      puts 'dummy supplier data'
      JSON File.read('data/' + 'facilities_management/dummy_supplier_data.json')
    elsif ENV['SECRET_KEY_BASE']
      puts 'real supplier data'
      JSON fm_aws
    end
  end

  def self.fm_suppliers
    ActiveRecord::Base.connection_pool.with_connection do |db|
      query = 'CREATE TABLE IF NOT EXISTS fm_suppliers ( supplier_id UUID PRIMARY KEY, data jsonb,' \
              '  created_at timestamp without time zone NOT NULL,  updated_at timestamp without time zone NOT NULL);' \
              'CREATE INDEX IF NOT EXISTS idxgin ON fm_suppliers USING GIN (data);' \
              'CREATE INDEX IF NOT EXISTS idxginp ON fm_suppliers USING GIN (data jsonb_path_ops);' \
              "CREATE INDEX IF NOT EXISTS idxginlots ON fm_suppliers USING GIN ((data -> 'lots'));"
      db.query query

      supplier_data.each do |supplier|
        values = supplier.to_json.gsub("'") { "''" }
        query = "DELETE FROM fm_suppliers where data->'supplier_id' ? '" + supplier['supplier_id'] + "' ; " \
                'insert into fm_suppliers ( created_at, updated_at, supplier_id, data ) values ( now(), now(), \'' \
                          + supplier['supplier_id'] + "', '" + values + "')"
        db.query query
      end
    end
  rescue PG::Error => e
    puts e.message
  end

  def self.fm_supplier_contact_details
    FacilitiesManagement::SupplierDetail.destroy_all
    supplier_contact_details = Roo::Spreadsheet.open(Rails.root.join('data', 'facilities_management', 'RM3830 Suppliers Details (for Dev & Test).xlsx'), extension: :xlsx)
    supplier_contact_details.sheet(0).drop(1).each do |row|
      sd = FacilitiesManagement::SupplierDetail.new(
        user: User.find_by(email: row[8]),
        name: row[1].to_s.strip,
        lot1a: row[2].to_s.strip.downcase == 'x',
        lot1b: row[3].to_s.strip.downcase == 'x',
        lot1c: row[4].to_s.strip.downcase == 'x',
        direct_award: row[5].to_s.strip.downcase == 'yes',
        sme: row[6].to_s.strip.downcase == 'yes',
        contact_name: row[7].to_s.strip,
        contact_email: row[8].to_s.strip,
        contact_number: row[9].to_s.strip,
        duns: row[10].to_s.strip,
        registration_number: row[11].to_s.strip,
        address_line_1: row[12].to_s.strip,
        address_line_2: row[13].to_s.strip,
        address_town: row[14].to_s.strip,
        address_county: row[15].to_s.strip,
        address_postcode: row[16].to_s.strip
      )
      sd.save(validate: false)
    end
  rescue PG::Error => e
    puts e.message
  end

  def self.extend_timeout
    Aws.config[:http_open_timeout] = 600
    Aws.config[:http_read_timeout] = 600
    Aws.config[:http_idle_timeout] = 600
  end

  def self.awd_credentials(access_key, secret_key, bucket, region)
    Aws.config[:credentials] = Aws::Credentials.new(access_key, secret_key)
    p "Importing from AWS bucket: #{bucket}, region: #{region}"

    extend_timeout
  end

  # EDITOR=vim rails credentials:edit
  def self.fm_aws
    ENV['RAILS_MASTER_KEY_2'] = ENV['SECRET_KEY_BASE'][0..31] if ENV['SECRET_KEY_BASE']
    creds = ActiveSupport::EncryptedConfiguration.new(
      config_path: Rails.root.join('config', 'credentials.yml.enc'),
      key_path: 'config/master.key',
      env_key: 'RAILS_MASTER_KEY_2',
      raise_if_missing_key: false # config.require_master_key
    )

    access_key = creds.aws_suppliers[:access_key_id]
    secret_key = creds.aws_suppliers[:secret_access_key]
    bucket = creds.aws_suppliers[:bucket]
    region = creds.aws_suppliers[:region]

    import_suppliers(access_key, secret_key, bucket, region)
  rescue StandardError => e
    puts e.message
  end

  def self.import_suppliers(access_key, secret_key, bucket, region)
    awd_credentials access_key, secret_key, bucket, region

    object = Aws::S3::Resource.new(region: region)
    object.bucket(bucket).objects.each do |obj|
      next unless obj.key.starts_with? 'suppliers/data/final'

      p 'Loading ' + obj.key

      data = obj.get.body
      return data.string
    rescue PG::Error => e
      puts e.message
    end
  end
end

namespace :db do
  desc 'download from aws'
  task aws: :environment do
    p 'Loading FM Suppliers static'
    DistributedLocks.distributed_lock(152) do
      CCS.fm_suppliers
      CCS.fm_supplier_contact_details
    end
  end

  desc 'add static data to the database'
  task static: :aws do
  end
end
