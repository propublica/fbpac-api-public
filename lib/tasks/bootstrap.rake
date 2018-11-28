namespace :bootstrap do 
	task create_admin_user: [:environment] do 
		Partner.create!({:email => "admin@example.com", :password => "password!", :password_confirmation => "password!"}) unless Partner.find_by(email: "admin@example.com")
		puts "Partners: #{Partner.count}"
	end
end 