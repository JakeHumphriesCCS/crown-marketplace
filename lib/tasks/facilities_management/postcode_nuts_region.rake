require 'csv'
require 'json'

namespace :db do
  desc 'import postcode and nuts region data which matches postcode to a region code'
  task importpostcoderegion: :environment do
    p 'Starting PostodesNutsRegions import'
    CSV.foreach(Rails.root.join('data', 'facilities_management', 'pc_uk_NUTS-2013_vFM-CAT.csv')) do |row|
      p 'Importing:' + row.to_s
      pnr = PostcodesNutsRegions.find_by(postcode: row[0].delete(' '))
      if pnr
        pnr.update(code: row[1])
      else
        PostcodesNutsRegions.create(postcode: row[0].delete(' '), code: row[1])
      end
    end
  end

  task run_postcodes_to_nuts_worker: :environment do
    FacilitiesManagement::PostcodesToNutsWorker.perform_async
  end
end
