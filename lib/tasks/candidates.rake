
require 'csv'

# loads candidates into Candidate model
# creates ElectoralDistrict when necessary
# creates Parties when necessary
# CloseRaces get created differently
# States should already exist

namespace :candidates do 
    task load_federal: [:environment] do 
        CSV.open(File.join(Rails.root, "lib", "candidate_facebook_urls.csv")).each do |row|
            # csv << [candidate.clean_name, candidate.facebook_url, 
            # candidate.office_state, candidate.district, candidate.branch, candidate.party ] 

            # name:string facebook_url:string office:string state:string district:string party:string facebook_page_id:string country:string

            party = Party.find_or_create_by(abbrev: row[5])

            ElectoralDistrict.find_or_create_by(
                state: row[2], 
                name: ["00", "99"].include?(row[3]) ? nil : row[3], 
                office: row[4],
                country: "US"
            )

            candidate = Candidate.find_or_initialize_by(facebook_url: row[1])
            candidate.update_attributes(
                state: row[2],
                district: ["00", "99"].include?(row[3]) ? nil : row[3],
                facebook_url: row[1],
                name: row[0],
                party: party.id,
                office: row[4]
            )
            candidate.save

        end
    end

    task load_state: [:environment] do 
        CSV.open(File.join(Rails.root, "lib", "facebook_state_cands.csv"), headers:true).each do |row|
            # candidate state   office  facebook_url

            ElectoralDistrict.find_or_create_by(office: row[2], country: "US", name: row[2], state: row[1])

            candidate = Candidate.find_or_initialize_by(facebook_url: row[3].downcase)
            candidate.update_attributes(name: row[0],
                             state: row[1],
                             office: row[2],
                             district: row[2] # I might regret this; bad data modeling, jeremy!
                )
            candidate.save
        end
    end

    task bridgemi: [:environment] do 
        # Race  Candidate's name    Facebook URL
        CSV.open(File.join(Rails.root, "lib", "2018 Michigan election races to watch - Sheet1.csv"), headers:true).each do |row|
            # candidate state   office  facebook_url

            row["Race"].gsub("SOS", "Secretary of State")

            ElectoralDistrict.find_or_create_by(office: row["Race"], country: "US", name: row["Race"], state: "MI")

            candidate = Candidate.find_or_initialize_by(facebook_url: row["Facebook URL"].downcase)
            candidate.update_attributes(name: row["Candidate's name"],
                             state: "MI",
                             office: row["Race"],
                             district: row["Race"] # I might regret this; bad data modeling, jeremy!
                )
            candidate.save
        end
    end
end