namespace :stations do
  desc "Import stations only if there are none yet (safe to run on every boot)"
  task ensure: :environment do
    if Station.exists? && ENV["FORCE_STATIONS_IMPORT"].blank?
      puts "Stations already imported (#{Station.count})"
    else
      Rake::Task["stations:import"].invoke
    end
  end
end
