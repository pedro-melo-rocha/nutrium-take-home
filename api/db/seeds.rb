require "faker"

Faker::Config.locale = :"pt-PT"

puts "Seeding…"

SERVICE_CATALOG = [
  { name: "Initial Consultation",   price_cents: 5500, duration_minutes: 60 },
  { name: "Follow-up Consultation", price_cents: 3500, duration_minutes: 30 },
  { name: "Sports Nutrition",       price_cents: 7000, duration_minutes: 60 },
  { name: "Weight Management",      price_cents: 6000, duration_minutes: 45 },
  { name: "Pediatric Nutrition",    price_cents: 6500, duration_minutes: 45 },
  { name: "Pregnancy Nutrition",    price_cents: 7000, duration_minutes: 60 },
  { name: "Diabetes Counseling",    price_cents: 5500, duration_minutes: 45 },
  { name: "Vegan/Vegetarian Plan",  price_cents: 5000, duration_minutes: 45 },
  { name: "Online Follow-up",       price_cents: 2500, duration_minutes: 30 },
  { name: "Body Composition Eval",  price_cents: 4000, duration_minutes: 30 }
].freeze

LOCATIONS = [ "Braga", "Porto", "Lisboa", "Guimarães", "Coimbra", "Online" ].freeze

TITLES = [ "Dietitian", "Clinical Nutritionist", "Sports Nutritionist", "Pediatric Nutritionist" ].freeze

NUTRITIONISTS = [
  { name: "Ana Margarida Silva",    email: "ana.silva@nutri.example",       location: "Braga"     },
  { name: "João Pedro Ferreira",    email: "joao.ferreira@nutri.example",   location: "Braga"     },
  { name: "Maria Inês Costa",       email: "maria.costa@nutri.example",     location: "Braga"     },
  { name: "Rui Manuel Santos",      email: "rui.santos@nutri.example",      location: "Braga"     },
  { name: "Catarina Oliveira",      email: "catarina.oliveira@nutri.example", location: "Porto"   },
  { name: "Pedro Miguel Almeida",   email: "pedro.almeida@nutri.example",   location: "Porto"     },
  { name: "Sofia Alexandra Lopes",  email: "sofia.lopes@nutri.example",     location: "Porto"     },
  { name: "Tiago André Rocha",      email: "tiago.rocha@nutri.example",     location: "Lisboa"    },
  { name: "Beatriz Carvalho",       email: "beatriz.carvalho@nutri.example", location: "Lisboa"   },
  { name: "Diogo Filipe Mendes",    email: "diogo.mendes@nutri.example",    location: "Guimarães" },
  { name: "Inês Sofia Rodrigues",   email: "ines.rodrigues@nutri.example",  location: "Guimarães" },
  { name: "Luís Carlos Pereira",    email: "luis.pereira@nutri.example",    location: "Coimbra"   }
].freeze

nutritionists = NUTRITIONISTS.each_with_index.map do |attrs, idx|
  nutri = Nutritionist.find_or_create_by!(email: attrs[:email]) do |n|
    n.name = attrs[:name]
  end

  nutri.update!(
    name: attrs[:name],
    title: TITLES[idx % TITLES.size],
    license_number: format("PT-%04d", 1000 + idx),
    photo_url: "https://i.pravatar.cc/150?u=#{attrs[:email]}"
  )
  nutri
end

nutritionists.each_with_index do |nutri, idx|
  home = NUTRITIONISTS[idx][:location]

  count = 2 + (idx % 3)
  picks = SERVICE_CATALOG.rotate(idx).first(count)

  picks.each_with_index do |svc_attrs, svc_idx|
    location =
      case svc_idx
      when 0 then home
      when 1 then "Online"
      else LOCATIONS.rotate(idx + svc_idx).first
      end

    nutri.services.find_or_create_by!(name: svc_attrs[:name], location: location) do |s|
      s.price_cents      = svc_attrs[:price_cents]
      s.duration_minutes = svc_attrs[:duration_minutes]
    end
  end
end

SAMPLE_REQUESTS = [
  { nutri_email: "ana.silva@nutri.example",   guest_name: "Sara Pinto",     guest_email: "sara.pinto@example.com",   days_from_now: 2, hour: 10 },
  { nutri_email: "ana.silva@nutri.example",   guest_name: "Hugo Martins",   guest_email: "hugo.martins@example.com", days_from_now: 3, hour: 14 },
  { nutri_email: "joao.ferreira@nutri.example", guest_name: "Marta Sousa",  guest_email: "marta.sousa@example.com",  days_from_now: 4, hour: 11 }
].freeze

SAMPLE_REQUESTS.each do |req|
  nutri = Nutritionist.find_by!(email: req[:nutri_email])
  service = nutri.services.first
  next unless service
  next if AppointmentRequest.exists?(guest_email: req[:guest_email], status: :pending)

  starts_at = (Date.current + req[:days_from_now]).to_time.change(hour: req[:hour])

  AppointmentRequest.create!(
    nutritionist: nutri,
    service: service,
    guest_name: req[:guest_name],
    guest_email: req[:guest_email],
    starts_at: starts_at
  )
end

puts "  Nutritionists:        #{Nutritionist.count}"
puts "  Services:             #{Service.count}"
puts "    Braga-located:      #{Service.where(location: 'Braga').count}"
puts "    Online services:    #{Service.where(location: 'Online').count}"
puts "  Appointment requests: #{AppointmentRequest.count} (pending=#{AppointmentRequest.pending.count})"
puts "Done."
